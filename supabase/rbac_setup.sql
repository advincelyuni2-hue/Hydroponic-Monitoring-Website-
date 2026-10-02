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

alter table public.notifications
  add column if not exists title text,
  add column if not exists parameter text,
  add column if not exists type text,
  add column if not exists source text not null default 'manual',
  add column if not exists alert_key text,
  add column if not exists current_value text,
  add column if not exists ideal_range text,
  add column if not exists recommendation text,
  add column if not exists is_read boolean not null default false,
  add column if not exists is_resolved boolean not null default false,
  add column if not exists resolved_at timestamptz,
  add column if not exists resolved_by uuid references auth.users(id) on delete set null,
  add column if not exists resolved_by_name text;

-- Sensor alerts are system-wide, so they do not belong to one employee.
alter table public.notifications alter column employee_id drop not null;
update public.notifications set source = 'manual' where source is null;
alter table public.notifications alter column source set default 'manual';
alter table public.notifications alter column source set not null;

-- At most one unresolved alert is allowed for the same parameter/direction.
create unique index if not exists notifications_one_unresolved_alert
on public.notifications (alert_key)
where alert_key is not null and is_resolved = false;

create table if not exists public.forecast_logs (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null default auth.uid() references auth.users(id) on delete cascade,
  parameter text not null,
  status_badge text not null,
  warning_text text not null,
  temperature text not null,
  ec_level text not null,
  callout_text text not null,
  current_val numeric not null,
  target_val numeric not null,
  suggested_fixes text[] not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.action_logs (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null default auth.uid() references auth.users(id) on delete cascade,
  parameter text not null,
  forecast_condition text not null,
  horizon_hours integer not null,
  current_ph numeric not null,
  current_ec numeric not null,
  current_temp numeric not null,
  suggested_fixes text[] not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.dismissed_action_logs (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null default auth.uid() references auth.users(id) on delete cascade,
  parameter text not null,
  forecast_condition text not null,
  horizon_hours integer not null,
  current_ph numeric not null,
  current_ec numeric not null,
  current_temp numeric not null,
  suggested_fixes text[] not null default '{}',
  created_at timestamptz not null default now()
);

-- Older versions of the forecasting branch created these tables without an
-- owner column. CREATE TABLE IF NOT EXISTS does not upgrade an existing table,
-- so add the column separately before the RLS policies reference it. Keep the
-- migrated column nullable because legacy rows have no reliable user owner;
-- new app inserts receive auth.uid() from the default.
alter table public.forecast_logs
  add column if not exists created_by uuid references auth.users(id) on delete cascade;
alter table public.forecast_logs
  alter column created_by set default auth.uid();

alter table public.action_logs
  add column if not exists created_by uuid references auth.users(id) on delete cascade;
alter table public.action_logs
  alter column created_by set default auth.uid();

alter table public.dismissed_action_logs
  add column if not exists created_by uuid references auth.users(id) on delete cascade;
alter table public.dismissed_action_logs
  alter column created_by set default auth.uid();

alter table public.forecast_logs enable row level security;
alter table public.action_logs enable row level security;
alter table public.dismissed_action_logs enable row level security;

grant select, insert on public.forecast_logs to authenticated;
grant select, insert on public.action_logs to authenticated;
grant select, insert on public.dismissed_action_logs to authenticated;

drop policy if exists "Users can create forecast logs" on public.forecast_logs;
create policy "Users can create forecast logs"
on public.forecast_logs for insert to authenticated
with check (created_by = auth.uid());
drop policy if exists "Users can read relevant forecast logs" on public.forecast_logs;
create policy "Users can read relevant forecast logs"
on public.forecast_logs for select to authenticated
using (created_by = auth.uid() or public.is_admin());

drop policy if exists "Users can create action logs" on public.action_logs;
create policy "Users can create action logs"
on public.action_logs for insert to authenticated
with check (created_by = auth.uid());
drop policy if exists "Users can read relevant action logs" on public.action_logs;
create policy "Users can read relevant action logs"
on public.action_logs for select to authenticated
using (created_by = auth.uid() or public.is_admin());

drop policy if exists "Users can create dismissed action logs" on public.dismissed_action_logs;
create policy "Users can create dismissed action logs"
on public.dismissed_action_logs for insert to authenticated
with check (created_by = auth.uid());
drop policy if exists "Users can read relevant dismissed action logs" on public.dismissed_action_logs;
create policy "Users can read relevant dismissed action logs"
on public.dismissed_action_logs for select to authenticated
using (created_by = auth.uid() or public.is_admin());

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
grant select, insert, delete on public.notifications to authenticated;
revoke update on public.notifications from authenticated;
grant update (is_resolved, status, is_read) on public.notifications to authenticated;

drop policy if exists "Employees can create alerts" on public.notifications;
create policy "Employees can create alerts"
on public.notifications for insert to authenticated
with check (
  employee_id = auth.uid()
  and not public.is_admin()
  and source = 'manual'
  and alert_key is null
  and is_resolved = false
);

drop policy if exists "Users can read relevant alerts" on public.notifications;
create policy "Users can read relevant alerts"
on public.notifications for select to authenticated
using (source = 'sensor' or employee_id = auth.uid() or public.is_admin());

drop policy if exists "Admins can update alerts" on public.notifications;
drop policy if exists "Users can update relevant alerts" on public.notifications;
create policy "Users can update relevant alerts"
on public.notifications for update to authenticated
using (source = 'sensor' or employee_id = auth.uid() or public.is_admin())
with check (source = 'sensor' or employee_id = auth.uid() or public.is_admin());

drop policy if exists "Admins can delete alerts" on public.notifications;
drop policy if exists "Users can delete relevant alerts" on public.notifications;
create policy "Admins can delete alerts"
on public.notifications for delete to authenticated
using (public.is_admin());

create or replace function public.stamp_notification_resolution()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.is_resolved is distinct from old.is_resolved then
    if new.is_resolved then
      new.resolved_at := now();
      new.resolved_by := auth.uid();
      select coalesce(nullif(trim(full_name), ''), email, 'User')
      into new.resolved_by_name
      from public.profiles
      where id = auth.uid();
      new.resolved_by_name := coalesce(new.resolved_by_name, 'User');
      new.status := 'read';
      new.is_read := true;
    else
      new.resolved_at := null;
      new.resolved_by := null;
      new.resolved_by_name := null;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists stamp_notification_resolution on public.notifications;
create trigger stamp_notification_resolution
before update of is_resolved on public.notifications
for each row execute function public.stamp_notification_resolution();

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
  unit_name text;
  direction_name text;
  severity_name text;
  recommendation_text text;
  alert_key_value text;
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
    unit_name := 'pH';
    minimum_value := coalesce(config.ph_min, 5.5);
    maximum_value := coalesce(config.ph_max, 6.5);
  elsif tg_table_name = 'ec_readings' then
    parameter_name := 'EC Level';
    unit_name := 'mS/cm';
    minimum_value := coalesce(config.ec_min, 1.2);
    maximum_value := coalesce(config.ec_max, 1.8);
  else
    parameter_name := 'Temperature';
    unit_name := '°C';
    minimum_value := 18;
    maximum_value := 28;
  end if;

  if new.value < minimum_value or new.value > maximum_value then
    direction_name := case when new.value < minimum_value then 'Low' else 'High' end;
    alert_key_value := format('%s:%s', tg_table_name, lower(direction_name));

    if tg_table_name = 'ph_readings' then
      severity_name := case when new.value < 5.0 or new.value > 7.0 then 'critical' else 'warning' end;
      recommendation_text := case
        when new.value < minimum_value then 'Add pH-up solution gradually, circulate the solution, and verify the reading before adding more.'
        else 'Add pH-down solution gradually, circulate the solution, and verify the reading before adding more.'
      end;
    elsif tg_table_name = 'ec_readings' then
      severity_name := case when new.value < 0.8 or new.value > 2.2 then 'critical' else 'warning' end;
      recommendation_text := case
        when new.value < minimum_value then 'Check the nutrient mixture and replenish nutrients gradually, then verify the EC reading.'
        else 'Check water level and nutrient concentration; dilute gradually with clean water, then verify the EC reading.'
      end;
    else
      severity_name := case when new.value < 15 or new.value > 30 then 'critical' else 'warning' end;
      recommendation_text := case
        when new.value < minimum_value then 'Inspect the heater and environment, raise the temperature gradually, and verify the sensor reading.'
        else 'Improve cooling or ventilation, inspect the reservoir, and verify the temperature sensor reading.'
      end;
    end if;

    -- Keep the existing unresolved alert current without creating or sending
    -- another notification for the same parameter and direction.
    update public.notifications
    set message = format('%s is %s at %s %s. The configured range is %s - %s %s.',
          parameter_name, lower(direction_name), new.value, unit_name,
          minimum_value, maximum_value, unit_name),
        type = severity_name,
        current_value = format('%s %s', new.value, unit_name),
        ideal_range = format('%s - %s %s', minimum_value, maximum_value, unit_name),
        recommendation = recommendation_text,
        timestamp = now()
    where alert_key = alert_key_value
      and is_resolved = false;

    if found then
      return new;
    end if;

    insert into public.notifications (
      employee_id, source, alert_key, parameter, title, message, type,
      current_value, ideal_range, recommendation, status, is_read, is_resolved
    ) values (
      null,
      'sensor',
      alert_key_value,
      parameter_name,
      format('%s %s', parameter_name, direction_name),
      format('%s is %s at %s %s. The configured range is %s - %s %s.',
        parameter_name, lower(direction_name), new.value, unit_name,
        minimum_value, maximum_value, unit_name),
      severity_name,
      format('%s %s', new.value, unit_name),
      format('%s - %s %s', minimum_value, maximum_value, unit_name),
      recommendation_text,
      'unread',
      false,
      false
    )
    on conflict do nothing;
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
