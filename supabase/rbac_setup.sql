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
  add column if not exists resolved_by_name text,
  add column if not exists lifecycle_state text not null default 'open',
  add column if not exists action_taken_at timestamptz,
  add column if not exists recovery_started_at timestamptz,
  add column if not exists stable_reading_count integer not null default 0;

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

create table if not exists public.forecast_predictions (
  id uuid primary key default gen_random_uuid(),
  baseline_history_id bigint not null references public.sensor_history(id) on delete cascade,
  baseline_recorded_at timestamptz not null,
  parameter text not null check (parameter in ('ph', 'ec')),
  horizon_hours integer not null check (horizon_hours in (4, 8, 12)),
  baseline_value numeric not null,
  predicted_value numeric not null,
  generated_at timestamptz not null default now(),
  target_at timestamptz not null,
  model_version text not null,
  actual_history_id bigint references public.sensor_history(id) on delete set null,
  actual_value numeric,
  actual_recorded_at timestamptz,
  evaluated_at timestamptz,
  evaluation_status text not null default 'pending'
    check (evaluation_status in ('pending', 'evaluated', 'intervened', 'missing_actual')),
  intervention_count integer not null default 0 check (intervention_count >= 0),
  unique (baseline_history_id, parameter, horizon_hours, model_version)
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
  notification_id uuid references public.notifications(id) on delete set null,
  forecast_prediction_id uuid references public.forecast_predictions(id) on delete set null,
  source text not null default 'manual',
  action_type text,
  amount numeric,
  amount_unit text not null default 'mL',
  notes text,
  performed_at timestamptz not null default now(),
  affected_parameters text[] not null default '{}',
  reservoir_volume_l numeric,
  sensor_history_id_before bigint references public.sensor_history(id) on delete set null,
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
alter table public.action_logs
  add column if not exists notification_id uuid references public.notifications(id) on delete set null,
  add column if not exists forecast_prediction_id uuid references public.forecast_predictions(id) on delete set null,
  add column if not exists source text not null default 'manual',
  add column if not exists action_type text,
  add column if not exists amount numeric,
  add column if not exists amount_unit text not null default 'mL',
  add column if not exists notes text,
  add column if not exists performed_at timestamptz not null default now(),
  add column if not exists affected_parameters text[] not null default '{}',
  add column if not exists reservoir_volume_l numeric,
  add column if not exists sensor_history_id_before bigint references public.sensor_history(id) on delete set null;

alter table public.notifications
  add column if not exists action_log_id uuid references public.action_logs(id) on delete set null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'notifications_lifecycle_state_check'
      and conrelid = 'public.notifications'::regclass
  ) then
    alter table public.notifications
      add constraint notifications_lifecycle_state_check
      check (lifecycle_state in ('open', 'action_taken', 'recovering', 'resolved'));
  end if;
end $$;

alter table public.dismissed_action_logs
  add column if not exists created_by uuid references auth.users(id) on delete cascade;
alter table public.dismissed_action_logs
  alter column created_by set default auth.uid();

alter table public.forecast_logs enable row level security;
alter table public.forecast_predictions enable row level security;
alter table public.action_logs enable row level security;
alter table public.dismissed_action_logs enable row level security;

grant select, insert on public.forecast_logs to authenticated;
grant select on public.forecast_predictions to authenticated;
revoke insert, update, delete on public.forecast_predictions from anon, authenticated;
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

drop policy if exists "Authenticated users can read forecast predictions" on public.forecast_predictions;
create policy "Authenticated users can read forecast predictions"
on public.forecast_predictions for select to authenticated using (true);

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
      new.resolved_by_name := coalesce(
        new.resolved_by_name,
        case when auth.uid() is null then 'System recovery' else 'User' end
      );
      new.status := 'read';
      new.is_read := true;
      new.lifecycle_state := 'resolved';
    else
      new.resolved_at := null;
      new.resolved_by := null;
      new.resolved_by_name := null;
      new.lifecycle_state := case
        when new.action_log_id is null then 'open' else 'action_taken'
      end;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists stamp_notification_resolution on public.notifications;
create trigger stamp_notification_resolution
before update of is_resolved on public.notifications
for each row execute function public.stamp_notification_resolution();

-- The alert trigger depends on this singleton configuration row. Create it
-- before installing the trigger so this script also works on a new project.
create table if not exists public.parameter_configurations (
  id integer primary key default 1 check (id = 1),
  ph_min numeric not null default 5.5,
  ph_max numeric not null default 6.5,
  ec_min numeric not null default 1.2,
  ec_max numeric not null default 1.8,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);

insert into public.parameter_configurations (id)
values (1)
on conflict (id) do nothing;

create or replace function public.apply_sensor_alert(
  parameter_key text,
  parameter_name text,
  measured_value numeric,
  stable_min numeric,
  stable_max numeric,
  warning_margin numeric,
  unit_name text,
  low_recommendation text,
  high_recommendation text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  direction_name text;
  severity_name text;
  recommendation_text text;
  alert_key_value text;
  measured_text text;
  stable_min_text text;
  stable_max_text text;
begin
  if measured_value between stable_min and stable_max then
    update public.notifications
    set stable_reading_count = stable_reading_count + 1,
        recovery_started_at = coalesce(recovery_started_at, now()),
        lifecycle_state = case
          when stable_reading_count + 1 >= 3 then 'resolved'
          else 'recovering'
        end,
        is_resolved = stable_reading_count + 1 >= 3,
        status = case when stable_reading_count + 1 >= 3 then 'read' else status end,
        is_read = case when stable_reading_count + 1 >= 3 then true else is_read end,
        timestamp = now()
    where source = 'sensor'
      and parameter = parameter_name
      and is_resolved = false;
    return;
  end if;

  direction_name := case when measured_value < stable_min then 'Low' else 'High' end;
  severity_name := case
    when measured_value < stable_min - warning_margin
      or measured_value > stable_max + warning_margin then 'critical'
    else 'warning'
  end;
  recommendation_text := case
    when measured_value < stable_min then low_recommendation
    else high_recommendation
  end;
  alert_key_value := format('sensor_history:%s:%s', parameter_key, lower(direction_name));
  measured_text := case
    when parameter_key = 'temp' then to_char(measured_value, 'FM999990.0')
    else to_char(measured_value, 'FM999990.000000')
  end;
  stable_min_text := case
    when parameter_key = 'temp' then to_char(stable_min, 'FM999990.0')
    else to_char(stable_min, 'FM999990.000000')
  end;
  stable_max_text := case
    when parameter_key = 'temp' then to_char(stable_max, 'FM999990.0')
    else to_char(stable_max, 'FM999990.000000')
  end;

  -- Close an unresolved alert in the opposite direction before opening the
  -- current incident.
  update public.notifications
  set is_resolved = true,
      lifecycle_state = 'resolved',
      status = 'read',
      is_read = true,
      timestamp = now()
  where source = 'sensor'
    and parameter = parameter_name
    and alert_key <> alert_key_value
    and is_resolved = false;

  update public.notifications
  set title = format('%s %s', parameter_name, direction_name),
      message = format(
        '%s five-minute average is %s at %s %s. Stable range: %s - %s %s.',
        parameter_name, lower(direction_name), measured_text, unit_name,
        stable_min_text, stable_max_text, unit_name
      ),
      type = severity_name,
      current_value = format('%s %s', measured_text, unit_name),
      ideal_range = format('%s - %s %s', stable_min_text, stable_max_text, unit_name),
      recommendation = recommendation_text,
      timestamp = now(),
      stable_reading_count = 0,
      recovery_started_at = null,
      lifecycle_state = case
        when action_log_id is null then 'open' else 'action_taken'
      end,
      status = case when type is distinct from severity_name then 'unread' else status end,
      is_read = case when type is distinct from severity_name then false else is_read end
  where alert_key = alert_key_value
    and is_resolved = false;

  if found then
    return;
  end if;

  insert into public.notifications (
    employee_id, source, alert_key, parameter, title, message, type,
    current_value, ideal_range, recommendation, status, is_read, is_resolved,
    lifecycle_state, stable_reading_count
  ) values (
    null,
    'sensor',
    alert_key_value,
    parameter_name,
    format('%s %s', parameter_name, direction_name),
    format(
      '%s five-minute average is %s at %s %s. Stable range: %s - %s %s.',
      parameter_name, lower(direction_name), measured_text, unit_name,
      stable_min_text, stable_max_text, unit_name
    ),
    severity_name,
    format('%s %s', measured_text, unit_name),
    format('%s - %s %s', stable_min_text, stable_max_text, unit_name),
    recommendation_text,
    'unread',
    false,
    false,
    'open',
    0
  ) on conflict do nothing;
end;
$$;

create or replace function public.evaluate_five_minute_alerts()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  config record;
begin
  select
    coalesce((select ph_min from public.parameter_configurations where id = 1), 5.5) as ph_min,
    coalesce((select ph_max from public.parameter_configurations where id = 1), 6.5) as ph_max,
    coalesce((select ec_min from public.parameter_configurations where id = 1), 1.2) as ec_min,
    coalesce((select ec_max from public.parameter_configurations where id = 1), 1.8) as ec_max
  into config
  ;

  perform public.apply_sensor_alert(
    'ph', 'pH Level', new.avg_ph::numeric,
    coalesce(config.ph_min, 5.5), coalesce(config.ph_max, 6.5), 0.5, 'pH',
    'Add pH-up solution gradually, circulate the solution, and verify the next five-minute average.',
    'Add pH-down solution gradually, circulate the solution, and verify the next five-minute average.'
  );
  perform public.apply_sensor_alert(
    'ec', 'EC Level', new.avg_ec::numeric,
    coalesce(config.ec_min, 1.2), coalesce(config.ec_max, 1.8), 0.5, 'mS/cm',
    'Check the nutrient mixture and replenish nutrients gradually, then verify the next five-minute average.',
    'Check water level and concentration; dilute gradually with clean water, then verify the next five-minute average.'
  );
  perform public.apply_sensor_alert(
    'temp', 'Temperature', new.avg_temp::numeric,
    18, 24, 5, '°C',
    'Inspect the heater and environment, raise temperature gradually, and verify the next five-minute average.',
    'Improve cooling or ventilation, inspect the reservoir, and verify the next five-minute average.'
  );
  return new;
end;
$$;

-- Remove the legacy per-parameter triggers so alerts are evaluated once from
-- the atomic five-minute sensor_history row.
do $$
declare
  table_name text;
begin
  foreach table_name in array array['ph_readings', 'ec_readings', 'temp_readings']
  loop
    if to_regclass(format('public.%s', table_name)) is not null then
      execute format('drop trigger if exists create_parameter_alert on public.%I', table_name);
    end if;
  end loop;
end $$;

drop trigger if exists evaluate_five_minute_alerts on public.sensor_history;
create trigger evaluate_five_minute_alerts
after insert on public.sensor_history
for each row execute function public.evaluate_five_minute_alerts();

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
    execute 'grant select, update, delete on table public.sensor_history to authenticated';
    execute 'drop policy if exists "Authenticated users can read history" on public.sensor_history';
    execute 'create policy "Authenticated users can read history" on public.sensor_history for select to authenticated using (true)';
    execute 'drop policy if exists "Admins can delete history" on public.sensor_history';
    execute 'create policy "Admins can delete history" on public.sensor_history for delete to authenticated using (public.is_admin())';
    execute 'drop policy if exists "Admins can update history" on public.sensor_history';
    execute 'create policy "Admins can update history" on public.sensor_history for update to authenticated using (public.is_admin()) with check (public.is_admin())';
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

-- Record an intervention and move its sensor alert into action_taken without
-- prematurely resolving it. The five-minute alert trigger resolves it only
-- after three consecutive stable readings.
create or replace function public.record_notification_intervention(
  notification_id_value uuid,
  parameter_value text,
  current_value_value numeric,
  current_status_value text,
  action_type_value text,
  amount_value numeric default 0,
  notes_value text default '',
  reservoir_volume_l_value numeric default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  actor uuid := auth.uid();
  latest_history public.sensor_history%rowtype;
  action_id uuid;
  affected text[];
begin
  if actor is null then
    raise exception 'Authentication is required.';
  end if;

  if not exists (
    select 1 from public.notifications n
    where n.id = notification_id_value
      and (n.source = 'sensor' or n.employee_id = actor or public.is_admin())
  ) then
    raise exception 'Notification is not available.';
  end if;

  select * into latest_history
  from public.sensor_history
  order by recorded_at desc
  limit 1;

  affected := case lower(action_type_value)
    when 'ph up' then array['ph', 'ec']
    when 'ph down' then array['ph', 'ec']
    when 'add nutrient' then array['ph', 'ec']
    when 'add water' then array['ph', 'ec']
    else array[lower(parameter_value)]
  end;

  insert into public.action_logs (
    created_by, parameter, forecast_condition, horizon_hours,
    current_ph, current_ec, current_temp, suggested_fixes,
    notification_id, source, action_type, amount, amount_unit, notes,
    performed_at, affected_parameters, reservoir_volume_l,
    sensor_history_id_before
  ) values (
    actor, parameter_value, current_status_value, 0,
    case when lower(parameter_value) in ('ph', 'ph level')
      then current_value_value else coalesce(latest_history.avg_ph, 0) end,
    case when lower(parameter_value) in ('ec', 'ec level')
      then current_value_value else coalesce(latest_history.avg_ec, 0) end,
    case when lower(parameter_value) in ('temperature', 'temp')
      then current_value_value else coalesce(latest_history.avg_temp, 0) end,
    array[
      'Action: ' || action_type_value,
      case when coalesce(amount_value, 0) > 0
        then 'Amount: ' || amount_value || ' mL' else 'Amount: not recorded' end,
      case when coalesce(notes_value, '') <> ''
        then 'Notes: ' || notes_value else 'Notes: not recorded' end,
      'Notification: ' || notification_id_value::text
    ],
    notification_id_value, 'notification_fix', action_type_value,
    amount_value, 'mL', nullif(trim(notes_value), ''), now(), affected,
    reservoir_volume_l_value, latest_history.id
  ) returning id into action_id;

  update public.notifications
  set lifecycle_state = 'action_taken',
      action_taken_at = now(),
      action_log_id = action_id,
      stable_reading_count = 0,
      recovery_started_at = null,
      status = 'read',
      is_read = true
  where id = notification_id_value;

  return action_id;
end;
$$;

grant execute on function public.record_notification_intervention(
  uuid, text, numeric, text, text, numeric, text, numeric
) to authenticated;

-- Match a saved forecast to the first five-minute reading at or just after
-- its target. Any intervention between baseline and actual is preserved as a
-- separate evaluation status rather than counted against model accuracy.
create or replace function public.evaluate_due_forecasts()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.forecast_predictions prediction
  set actual_history_id = new.id,
      actual_value = case prediction.parameter
        when 'ph' then new.avg_ph else new.avg_ec end,
      actual_recorded_at = new.recorded_at,
      evaluated_at = now(),
      intervention_count = (
        select count(*)::integer from public.action_logs action
        where action.performed_at > prediction.baseline_recorded_at
          and action.performed_at <= new.recorded_at
          and (
            prediction.parameter = any(action.affected_parameters)
            or lower(action.parameter) = prediction.parameter
            or lower(action.parameter) = prediction.parameter || ' level'
          )
      ),
      evaluation_status = case when exists (
        select 1 from public.action_logs action
        where action.performed_at > prediction.baseline_recorded_at
          and action.performed_at <= new.recorded_at
          and (
            prediction.parameter = any(action.affected_parameters)
            or lower(action.parameter) = prediction.parameter
            or lower(action.parameter) = prediction.parameter || ' level'
          )
      ) then 'intervened' else 'evaluated' end
  where prediction.evaluation_status = 'pending'
    and prediction.target_at <= new.recorded_at
    and new.recorded_at <= prediction.target_at + interval '15 minutes';

  update public.forecast_predictions
  set evaluation_status = 'missing_actual', evaluated_at = now()
  where evaluation_status = 'pending'
    and target_at < new.recorded_at - interval '15 minutes';
  return new;
end;
$$;

drop trigger if exists evaluate_due_forecasts on public.sensor_history;
create trigger evaluate_due_forecasts
after insert on public.sensor_history
for each row execute function public.evaluate_due_forecasts();

create or replace view public.forecast_prediction_evaluations
with (security_invoker = true)
as
select
  prediction.*,
  case when actual_value is null then null
    else actual_value - predicted_value end as signed_error,
  case when actual_value is null then null
    else abs(actual_value - predicted_value) end as absolute_error,
  case when actual_value is null or actual_value = 0 then null
    else abs(actual_value - predicted_value) / abs(actual_value) * 100 end
    as percentage_error,
  case when actual_value is null then null
    else power(actual_value - predicted_value, 2) end as squared_error
from public.forecast_predictions prediction;

grant select on public.forecast_prediction_evaluations to authenticated;

-- Promote an administrator manually, never from the public signup flow:
-- update public.profiles set role = 'admin' where email = 'admin@example.com';
