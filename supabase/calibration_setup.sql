-- Run once in the Supabase SQL editor before using the guided calibration UI.
-- One ESP32 supplies all three measurements, so calibration pauses the whole
-- five-minute sensor_history row rather than publishing mixed buffer readings.

create table if not exists public.calibration_sessions (
  id uuid primary key default gen_random_uuid(),
  device_id text not null default 'hydroponic-esp32',
  parameter text not null check (parameter in ('ph', 'tds')),
  status text not null default 'in_progress'
    check (status in ('in_progress', 'completed', 'cancelled', 'failed')),
  created_by uuid not null default auth.uid() references auth.users(id),
  operator_name text not null,
  notes text,
  started_at timestamptz not null default now(),
  completed_at timestamptz
);

create unique index if not exists calibration_one_active_per_device
  on public.calibration_sessions (device_id) where status = 'in_progress';

create table if not exists public.calibration_device_state (
  device_id text primary key,
  active_session_id uuid references public.calibration_sessions(id),
  active_parameter text check (active_parameter in ('ph', 'tds')),
  ph4_voltage double precision,
  ph7_voltage double precision,
  tds_factor double precision,
  coefficients_version bigint not null default 0,
  applied_version bigint not null default 0,
  maintenance_epoch bigint not null default 0,
  last_completed_session_id uuid references public.calibration_sessions(id),
  resume_after timestamptz,
  updated_at timestamptz not null default now(),
  check ((active_session_id is null) = (active_parameter is null)),
  check (ph4_voltage is null or ph4_voltage between 0.01 and 3.3),
  check (ph7_voltage is null or ph7_voltage between 0.01 and 3.3),
  check (tds_factor is null or tds_factor between 0.1 and 10)
);

insert into public.calibration_device_state (device_id)
values ('hydroponic-esp32') on conflict (device_id) do nothing;

create table if not exists public.calibration_samples (
  id bigint generated always as identity primary key,
  session_id uuid not null references public.calibration_sessions(id) on delete cascade,
  device_id text not null,
  parameter text not null check (parameter in ('ph', 'tds')),
  voltage double precision not null check (voltage between 0 and 3.3),
  recorded_at timestamptz not null default now()
);

create index if not exists calibration_samples_recent
  on public.calibration_samples (session_id, recorded_at desc);

create table if not exists public.calibration_points (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.calibration_sessions(id) on delete cascade,
  standard_label text not null,
  expected_value numeric not null,
  expected_unit text not null,
  voltage double precision not null check (voltage between 0 and 3.3),
  solution_temperature_c numeric,
  sample_count integer not null check (sample_count >= 3),
  voltage_range double precision not null check (voltage_range >= 0),
  captured_at timestamptz not null default now(),
  unique (session_id, standard_label)
);

alter table public.calibration_logs
  add column if not exists calibration_session_id uuid
  references public.calibration_sessions(id);

alter table public.calibration_sessions enable row level security;
alter table public.calibration_device_state enable row level security;
alter table public.calibration_samples enable row level security;
alter table public.calibration_points enable row level security;

grant select on public.calibration_sessions to authenticated;
revoke insert on public.calibration_sessions from authenticated;
revoke update on public.calibration_sessions from authenticated;
grant select on public.calibration_device_state to authenticated;
revoke update on public.calibration_device_state from authenticated;
grant select on public.calibration_device_state to anon;
grant select on public.calibration_samples to authenticated;
grant insert on public.calibration_samples to anon;
grant usage, select on sequence public.calibration_samples_id_seq to anon;
grant select, insert on public.calibration_points to authenticated;

drop policy if exists calibration_sessions_read on public.calibration_sessions;
create policy calibration_sessions_read on public.calibration_sessions
  for select to authenticated using (true);
drop policy if exists calibration_sessions_insert on public.calibration_sessions;
drop policy if exists calibration_sessions_update on public.calibration_sessions;

drop policy if exists calibration_state_read on public.calibration_device_state;
create policy calibration_state_read on public.calibration_device_state
  for select to anon, authenticated using (true);
drop policy if exists calibration_state_update on public.calibration_device_state;

drop policy if exists calibration_samples_read on public.calibration_samples;
create policy calibration_samples_read on public.calibration_samples
  for select to authenticated using (true);
drop policy if exists calibration_samples_insert on public.calibration_samples;
create policy calibration_samples_insert on public.calibration_samples
  for insert to anon with check (
    exists (
      select 1 from public.calibration_device_state state
      where state.device_id = calibration_samples.device_id
        and state.active_session_id = calibration_samples.session_id
        and state.active_parameter = calibration_samples.parameter
    )
  );

drop policy if exists calibration_points_read on public.calibration_points;
create policy calibration_points_read on public.calibration_points
  for select to authenticated using (true);
drop policy if exists calibration_points_insert on public.calibration_points;
create policy calibration_points_insert on public.calibration_points
  for insert to authenticated with check (
    exists (
      select 1 from public.calibration_sessions session
      where session.id = session_id
        and session.status = 'in_progress'
        and session.created_by = auth.uid()
    )
  );

-- Finished and cancelled attempts appear in History Logs and PDF reports.
create or replace function public.log_calibration_attempt()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  details text;
begin
  if new.status in ('completed', 'cancelled', 'failed')
      and old.status = 'in_progress' then
    select string_agg(
      standard_label || ': ' || round(voltage::numeric, 4)::text || ' V',
      ' • ' order by captured_at
    ) into details from public.calibration_points where session_id = new.id;
    insert into public.calibration_logs (
      recorded_at, parameter, calibration_type, adjustment,
      performed_by, status, created_by, calibration_session_id
    ) values (
      coalesce(new.completed_at, now()),
      case new.parameter when 'tds' then 'EC (TDS-derived)' else 'pH' end,
      case new.parameter when 'tds' then '1413 µS/cm TDS standard'
        else 'pH 7.00 / 4.00 two-point' end,
      coalesce(details, 'No points recorded'),
      new.operator_name,
      case when new.status = 'completed' then 'Pending device'
        when new.status = 'cancelled' then 'Cancelled'
        else 'Failed' end,
      new.created_by, new.id
    );
  end if;
  return new;
end $$;

drop trigger if exists calibration_completed_log on public.calibration_sessions;
create trigger calibration_completed_log after update on public.calibration_sessions
  for each row execute function public.log_calibration_attempt();

-- Forecasts made from the pre-calibration baseline stay auditable but are not
-- scored as model errors after sensor coefficients change.
do $$
declare existing_check record;
begin
  for existing_check in
    select conname from pg_constraint
    where conrelid = 'public.forecast_predictions'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) like '%evaluation_status%'
  loop
    execute format('alter table public.forecast_predictions drop constraint %I',
      existing_check.conname);
  end loop;
end $$;
alter table public.forecast_predictions
  add constraint forecast_predictions_evaluation_status_check
  check (evaluation_status in (
    'pending', 'evaluated', 'intervened', 'missing_actual', 'calibration_excluded'
  ));

-- Atomic session transitions ensure that a cancelled browser tab or a second
-- operator cannot silently change the device's active coefficients.
create or replace function public.begin_calibration(target_parameter text)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  actor uuid := auth.uid();
  new_id uuid;
  operator_label text;
begin
  if actor is null or target_parameter not in ('ph', 'tds') then
    raise exception 'A signed-in operator and valid parameter are required.';
  end if;
  perform 1 from public.calibration_device_state
    where device_id = 'hydroponic-esp32' for update;
  if exists (select 1 from public.calibration_device_state
      where device_id = 'hydroponic-esp32' and active_session_id is not null) then
    raise exception 'A calibration is already in progress.';
  end if;
  select coalesce(nullif(trim(full_name), ''), email, 'Operator')
    into operator_label from public.profiles where id = actor;
  insert into public.calibration_sessions (parameter, created_by, operator_name)
    values (target_parameter, actor, coalesce(operator_label, 'Operator'))
    returning id into new_id;
  update public.forecast_predictions
    set evaluation_status = 'calibration_excluded', evaluated_at = now()
    where evaluation_status = 'pending';
  update public.calibration_device_state
    set active_session_id = new_id, active_parameter = target_parameter,
      maintenance_epoch = maintenance_epoch + 1,
      updated_at = now(), resume_after = null
    where device_id = 'hydroponic-esp32';
  return new_id;
end $$;

create or replace function public.finish_calibration(session_id_value uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  s public.calibration_sessions%rowtype;
  v4 double precision;
  v7 double precision;
  v1413 double precision;
  base_ppm double precision;
  standard_temp numeric;
begin
  select * into s from public.calibration_sessions where id = session_id_value for update;
  if s.id is null or s.status <> 'in_progress'
      or (s.created_by <> auth.uid() and not public.is_admin()) then
    raise exception 'Calibration session is not available.';
  end if;
  if s.parameter = 'ph' then
    select voltage into v4 from public.calibration_points
      where session_id = s.id and standard_label = 'pH 4.00'
        and expected_value = 4 and expected_unit = 'pH';
    select voltage into v7 from public.calibration_points
      where session_id = s.id and standard_label = 'pH 7.00'
        and expected_value = 7 and expected_unit = 'pH';
    if v4 is null or v7 is null or abs(v4 - v7) < 0.02 then
      raise exception 'Capture distinct stable pH 7 and pH 4 points first.';
    end if;
    update public.calibration_device_state set
      ph4_voltage = v4, ph7_voltage = v7,
      coefficients_version = coefficients_version + 1,
      last_completed_session_id = s.id,
      maintenance_epoch = maintenance_epoch + 1,
      active_session_id = null, active_parameter = null,
      resume_after = now() + interval '1 minute', updated_at = now()
      where device_id = s.device_id and active_session_id = s.id;
  else
    select voltage, solution_temperature_c into v1413, standard_temp
      from public.calibration_points
      where session_id = s.id and standard_label = '1413 µS/cm'
        and expected_value = 1413 and expected_unit = 'µS/cm';
    if v1413 is null or standard_temp is null
        or standard_temp < 24 or standard_temp > 26 then
      raise exception 'Capture 1413 µS/cm with solution at 24–26 °C first.';
    end if;
    base_ppm := (133.42 * v1413^3 - 255.86 * v1413^2
      + 857.39 * v1413) * 0.5;
    if base_ppm <= 0 or (707 / base_ppm) not between 0.1 and 10 then
      raise exception 'TDS calibration voltage is outside the supported range.';
    end if;
    update public.calibration_device_state set
      tds_factor = 707 / base_ppm,
      coefficients_version = coefficients_version + 1,
      last_completed_session_id = s.id,
      maintenance_epoch = maintenance_epoch + 1,
      active_session_id = null, active_parameter = null,
      resume_after = now() + interval '1 minute', updated_at = now()
      where device_id = s.device_id and active_session_id = s.id;
  end if;
  if not found then raise exception 'Device state changed during calibration.'; end if;
  update public.calibration_sessions set status = 'completed', completed_at = now()
    where id = s.id;
end $$;

create or replace function public.ack_calibration_version(
  target_device_id text, target_version bigint
)
returns void language plpgsql security definer set search_path = public as $$
declare
  last_session uuid;
begin
  update public.calibration_device_state
    set applied_version = target_version, updated_at = now()
    where device_id = target_device_id
      and coefficients_version = target_version
      and applied_version < target_version
    returning last_completed_session_id into last_session;
  if last_session is not null then
    update public.calibration_logs set status = 'Completed'
      where calibration_session_id = last_session;
  end if;
end $$;

create or replace function public.cancel_calibration(session_id_value uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  s public.calibration_sessions%rowtype;
begin
  select * into s from public.calibration_sessions where id = session_id_value for update;
  if s.id is null or s.status <> 'in_progress'
      or (s.created_by <> auth.uid() and not public.is_admin()) then
    raise exception 'Calibration session is not available.';
  end if;
  update public.calibration_device_state set
    active_session_id = null, active_parameter = null,
    maintenance_epoch = maintenance_epoch + 1,
    resume_after = now() + interval '1 minute', updated_at = now()
    where device_id = s.device_id and active_session_id = s.id;
  update public.calibration_sessions set status = 'cancelled', completed_at = now()
    where id = s.id;
end $$;

revoke all on function public.begin_calibration(text) from public;
revoke all on function public.finish_calibration(uuid) from public;
revoke all on function public.cancel_calibration(uuid) from public;
revoke all on function public.ack_calibration_version(text, bigint) from public;
grant execute on function public.begin_calibration(text) to authenticated;
grant execute on function public.finish_calibration(uuid) to authenticated;
grant execute on function public.cancel_calibration(uuid) to authenticated;
grant execute on function public.ack_calibration_version(text, bigint) to anon;

-- This protects the shared pH/EC/air-temperature history row even if firmware
-- has not yet received a maintenance-state poll.
create or replace function public.reject_history_during_calibration()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from public.calibration_device_state
      where device_id = 'hydroponic-esp32'
        and (active_session_id is not null or resume_after > now())) then
    raise exception 'Sensor history is paused during calibration and settling.';
  end if;
  return new;
end $$;

drop trigger if exists pause_history_for_calibration on public.sensor_history;
create trigger pause_history_for_calibration before insert on public.sensor_history
  for each row execute function public.reject_history_during_calibration();
