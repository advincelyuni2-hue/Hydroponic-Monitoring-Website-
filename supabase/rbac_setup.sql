-- Run this script in the Supabase SQL Editor after the existing sensor tables
-- have been created. Admins are promoted manually; signup never accepts a role.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  role text not null default 'employee' check (role in ('admin', 'employee')),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
grant select on public.profiles to authenticated;
grant update (full_name, email) on public.profiles to authenticated;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and is_active
  );
$$;

drop policy if exists "Users can read their own profile" on public.profiles;
create policy "Users can read their own profile"
on public.profiles for select to authenticated
using (id = auth.uid() or public.is_admin());

drop policy if exists "Admins can update profiles" on public.profiles;
create policy "Admins can update profiles"
on public.profiles for update to authenticated
using (public.is_admin())
with check (public.is_admin());

-- FIX 1: without this, a regular user's own profile edit (name/email) matches
-- no UPDATE policy and silently affects 0 rows, since the only existing
-- UPDATE policy requires is_admin(). The column grant above already excludes
-- `role`, so this cannot be used to self-promote to admin.
drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
on public.profiles for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

insert into public.profiles (id, full_name, email)
select id, raw_user_meta_data ->> 'full_name', email
from auth.users
on conflict (id) do update
set email = excluded.email,
    full_name = coalesce(public.profiles.full_name, excluded.full_name);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email)
  values (new.id, new.raw_user_meta_data ->> 'full_name', new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references auth.users(id) on delete cascade,
  message text not null,
  timestamp timestamptz not null default now(),
  status text not null default 'unread' check (status in ('unread', 'read')),
  created_at timestamptz not null default now()
);

create table if not exists public.calibration_logs (
  id uuid primary key default gen_random_uuid(),
  recorded_at timestamptz not null default now(),
  parameter text not null,
  calibration_type text not null,
  adjustment text not null default '',
  performed_by text not null default 'Unknown',
  status text not null default 'Completed',
  created_by uuid references auth.users(id) on delete set null
);

alter table public.calibration_logs enable row level security;
grant select on public.calibration_logs to authenticated;
grant delete on public.calibration_logs to authenticated;

drop policy if exists "Authenticated users can read calibration logs" on public.calibration_logs;
create policy "Authenticated users can read calibration logs"
on public.calibration_logs for select to authenticated using (true);

drop policy if exists "Admins can delete calibration logs" on public.calibration_logs;
create policy "Admins can delete calibration logs"
on public.calibration_logs for delete to authenticated using (public.is_admin());

create table if not exists public.help_articles (
  id uuid primary key default gen_random_uuid(),
  type text not null default 'faq' check (type in ('tutorial', 'faq')),
  title text not null,
  body text not null,
  media_url text,
  created_by uuid references auth.users(id) on delete set null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.help_articles enable row level security;
grant select on public.help_articles to authenticated;
grant insert, update, delete on public.help_articles to authenticated;
drop policy if exists "Authenticated users can read help articles" on public.help_articles;
create policy "Authenticated users can read help articles"
on public.help_articles for select to authenticated using (true);
drop policy if exists "Admins can manage help articles" on public.help_articles;
create policy "Admins can manage help articles"
on public.help_articles for all to authenticated
using (public.is_admin()) with check (public.is_admin());

alter table public.notifications enable row level security;
grant select, insert, update, delete on public.notifications to authenticated;

drop policy if exists "Employees can create alerts" on public.notifications;
create policy "Employees can create alerts"
on public.notifications for insert to authenticated
with check (employee_id = auth.uid() and not public.is_admin());

drop policy if exists "Users can read relevant alerts" on public.notifications;
create policy "Users can read relevant alerts"
on public.notifications for select to authenticated
using (employee_id = auth.uid() or public.is_admin());

drop policy if exists "Admins can update alerts" on public.notifications;
create policy "Admins can update alerts"
on public.notifications for update to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "Admins can delete alerts" on public.notifications;
drop policy if exists "Users can delete relevant alerts" on public.notifications;
create policy "Admins can delete alerts"
on public.notifications for delete to authenticated
using (public.is_admin());

create or replace function public.create_parameter_alert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  config record;
  minimum_value numeric;
  maximum_value numeric;
  parameter_name text;
begin
  if coalesce(new.is_average, false) then
    return new;
  end if;

  select ph_min, ph_max, ec_min, ec_max
  into config
  from public.parameter_configurations
  where id = 1;

  if tg_table_name = 'ph_readings' then
    parameter_name := 'pH Level';
    minimum_value := coalesce(config.ph_min, 5.5);
    maximum_value := coalesce(config.ph_max, 6.5);
  elsif tg_table_name = 'ec_readings' then
    parameter_name := 'EC Level';
    minimum_value := coalesce(config.ec_min, 1.2);
    maximum_value := coalesce(config.ec_max, 1.8);
  else
    parameter_name := 'Temperature';
    minimum_value := 18;
    maximum_value := 28;
  end if;

  if new.value < minimum_value or new.value > maximum_value then
    insert into public.notifications (employee_id, message, status)
    select id,
      format('%s reading %s is outside the configured range (%s - %s).',
        parameter_name, new.value, minimum_value, maximum_value),
      'unread'
    from public.profiles
    where role = 'admin' and is_active;
  end if;
  return new;
end;
$$;

do $$
declare
  table_name text;
begin
  foreach table_name in array array['ph_readings', 'ec_readings', 'temp_readings']
  loop
    if to_regclass(format('public.%s', table_name)) is not null then
      execute format('drop trigger if exists create_parameter_alert on public.%I', table_name);
      execute format(
        'create trigger create_parameter_alert after insert on public.%I for each row execute function public.create_parameter_alert()',
        table_name
      );
    end if;
  end loop;
end $$;

create table if not exists public.parameter_configurations (
  id integer primary key default 1 check (id = 1),
  ph_min numeric not null default 5.5,
  ph_max numeric not null default 6.5,
  ec_min numeric not null default 1.2,
  ec_max numeric not null default 1.8,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);

alter table public.parameter_configurations enable row level security;
grant select on public.parameter_configurations to authenticated;
grant insert, update on public.parameter_configurations to authenticated;

-- NOTE: this currently lets ANY authenticated user (including employees)
-- read the pH/EC thresholds, even though only admins can edit them. If your
-- spec means employees shouldn't see this screen/data at all, change
-- `using (true)` below to `using (public.is_admin())`.
drop policy if exists "Authenticated users can read parameter configuration" on public.parameter_configurations;
create policy "Authenticated users can read parameter configuration"
on public.parameter_configurations for select to authenticated using (true);

drop policy if exists "Admins can write parameter configuration" on public.parameter_configurations;
create policy "Admins can write parameter configuration"
on public.parameter_configurations for insert to authenticated
with check (public.is_admin());

-- FIX 3: this policy had no matching `drop policy if exists` before it, so
-- re-running the script a second time would error with "policy already
-- exists" and stop partway through.
drop policy if exists "Admins can update parameter configuration" on public.parameter_configurations;
create policy "Admins can update parameter configuration"
on public.parameter_configurations for update to authenticated
using (public.is_admin())
with check (public.is_admin());

-- The app currently reads sensor_history for its History Logs screen. If a
-- separately named history_logs table exists, apply the same policies there.
do $$
begin
  if to_regclass('public.sensor_history') is not null then
    execute 'alter table public.sensor_history enable row level security';
    execute 'grant select, delete on table public.sensor_history to authenticated';
    execute 'drop policy if exists "Authenticated users can read history" on public.sensor_history';
    execute 'create policy "Authenticated users can read history" on public.sensor_history for select to authenticated using (true)';
    execute 'drop policy if exists "Admins can delete history" on public.sensor_history';
    execute 'create policy "Admins can delete history" on public.sensor_history for delete to authenticated using (public.is_admin())';
  end if;
  if to_regclass('public.history_logs') is not null then
    execute 'alter table public.history_logs enable row level security';
    execute 'grant select, delete on table public.history_logs to authenticated';
    execute 'drop policy if exists "Authenticated users can read history" on public.history_logs';
    execute 'create policy "Authenticated users can read history" on public.history_logs for select to authenticated using (true)';
    execute 'drop policy if exists "Admins can delete history" on public.history_logs';
    execute 'create policy "Admins can delete history" on public.history_logs for delete to authenticated using (public.is_admin())';
  end if;
  -- action_logs is the table the app's History Logs screen actually queries.
  -- It already has its own SELECT/INSERT policies (scoped to `public`, not
  -- touched here) but had no DELETE policy at all, so deletes were fully
  -- blocked for everyone. This adds an admin-only delete path.
  if to_regclass('public.action_logs') is not null then
    execute 'grant delete on table public.action_logs to authenticated';
    execute 'drop policy if exists "Admins can delete action logs" on public.action_logs';
    execute 'create policy "Admins can delete action logs" on public.action_logs for delete to authenticated using (public.is_admin())';
  end if;
end $$;

-- FIX 4: guarded with an information_schema check for an `is_average` column
-- so this block is skipped (instead of erroring and halting the script) on
-- any of these tables that don't have that column.
do $$
declare
  tbl_name text;
begin
  foreach tbl_name in array array['ph_readings', 'ec_readings', 'temp_readings']
  loop
    if to_regclass(format('public.%s', tbl_name)) is not null
       and exists (
         select 1 from information_schema.columns c
         where c.table_schema = 'public'
           and c.table_name = tbl_name
           and c.column_name = 'is_average'
       )
    then
      execute format('grant delete on table public.%I to authenticated', tbl_name);
      execute format('drop policy if exists "Admins can delete averaged history" on public.%I', tbl_name);
      execute format(
        'create policy "Admins can delete averaged history" on public.%I for delete to authenticated using (is_average = true and public.is_admin())',
        tbl_name
      );
    end if;
  end loop;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;

-- Promote an administrator manually, never from the public signup flow:
-- update public.profiles set role = 'admin' where email = 'admin@example.com';
