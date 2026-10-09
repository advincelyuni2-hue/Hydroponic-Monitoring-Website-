-- Persistent forecast evaluation, structured interventions, and sensor-alert
-- recovery. Run after realtime_setup.sql and rbac_setup.sql.
-- Then run manual_intervention_time_setup.sql for backdated manual actions.

-- Older deployments use UUID sensor_history IDs while newer clean installs use
-- bigint identities. Mirror the deployed key type so both schemas are valid.
do $migration$
declare
  sensor_history_id_type text;
begin
  select format_type(attribute.atttypid, attribute.atttypmod)
  into sensor_history_id_type
  from pg_attribute attribute
  where attribute.attrelid = 'public.sensor_history'::regclass
    and attribute.attname = 'id'
    and not attribute.attisdropped;

  if sensor_history_id_type is null then
    raise exception 'public.sensor_history.id does not exist';
  end if;

  execute format($table_definition$
    create table if not exists public.forecast_predictions (
      id uuid primary key default gen_random_uuid(),
      baseline_history_id %1$s not null
        references public.sensor_history(id) on delete cascade,
      baseline_recorded_at timestamptz not null,
      parameter text not null check (parameter in ('ph', 'ec')),
      horizon_hours integer not null check (horizon_hours in (4, 8, 12)),
      baseline_value numeric not null,
      predicted_value numeric not null,
      generated_at timestamptz not null default now(),
      target_at timestamptz not null,
      model_version text not null,
      actual_history_id %1$s
        references public.sensor_history(id) on delete set null,
      actual_value numeric,
      actual_recorded_at timestamptz,
      evaluated_at timestamptz,
      evaluation_status text not null default 'pending'
        check (evaluation_status in ('pending', 'evaluated', 'intervened', 'missing_actual')),
      intervention_count integer not null default 0 check (intervention_count >= 0),
      unique (baseline_history_id, parameter, horizon_hours, model_version)
    )
  $table_definition$, sensor_history_id_type);
end
$migration$;

create index if not exists forecast_predictions_target_pending_idx
on public.forecast_predictions (target_at)
where evaluation_status = 'pending';

create index if not exists forecast_predictions_evaluation_idx
on public.forecast_predictions (parameter, horizon_hours, evaluation_status, target_at desc);

alter table public.forecast_predictions enable row level security;
grant select on public.forecast_predictions to authenticated;
revoke insert, update, delete on public.forecast_predictions from anon, authenticated;

drop policy if exists "Authenticated users can read forecast predictions"
on public.forecast_predictions;
create policy "Authenticated users can read forecast predictions"
on public.forecast_predictions for select to authenticated using (true);

alter table public.action_logs
  add column if not exists notification_id uuid
    references public.notifications(id) on delete set null,
  add column if not exists forecast_prediction_id uuid
    references public.forecast_predictions(id) on delete set null,
  add column if not exists source text not null default 'manual',
  add column if not exists action_type text,
  add column if not exists amount numeric,
  add column if not exists amount_unit text not null default 'mL',
  add column if not exists notes text,
  add column if not exists performed_at timestamptz not null default now(),
  add column if not exists affected_parameters text[] not null default '{}',
  add column if not exists reservoir_volume_l numeric;

do $migration$
declare
  sensor_history_id_type text;
begin
  select format_type(attribute.atttypid, attribute.atttypmod)
  into sensor_history_id_type
  from pg_attribute attribute
  where attribute.attrelid = 'public.sensor_history'::regclass
    and attribute.attname = 'id'
    and not attribute.attisdropped;

  if sensor_history_id_type is null then
    raise exception 'public.sensor_history.id does not exist';
  end if;

  execute format(
    'alter table public.action_logs add column if not exists '
    'sensor_history_id_before %s references public.sensor_history(id) on delete set null',
    sensor_history_id_type
  );
end
$migration$;

create index if not exists action_logs_performed_at_idx
on public.action_logs (performed_at desc);

alter table public.notifications
  add column if not exists lifecycle_state text not null default 'open',
  add column if not exists action_taken_at timestamptz,
  add column if not exists recovery_started_at timestamptz,
  add column if not exists stable_reading_count integer not null default 0;

-- action_logs.id is bigint in some deployed projects and UUID in newer clean
-- installs. Mirror the deployed key type for the notification relationship.
do $migration$
declare
  action_log_id_type text;
begin
  select format_type(attribute.atttypid, attribute.atttypmod)
  into action_log_id_type
  from pg_attribute attribute
  where attribute.attrelid = 'public.action_logs'::regclass
    and attribute.attname = 'id'
    and not attribute.attisdropped;

  if action_log_id_type is null then
    raise exception 'public.action_logs.id does not exist';
  end if;

  execute format(
    'alter table public.notifications add column if not exists '
    'action_log_id %s references public.action_logs(id) on delete set null',
    action_log_id_type
  );
end
$migration$;

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
  measured_text := case when parameter_key = 'temp'
    then to_char(measured_value, 'FM999990.0')
    else to_char(measured_value, 'FM999990.000000') end;
  stable_min_text := case when parameter_key = 'temp'
    then to_char(stable_min, 'FM999990.0')
    else to_char(stable_min, 'FM999990.000000') end;
  stable_max_text := case when parameter_key = 'temp'
    then to_char(stable_max, 'FM999990.0')
    else to_char(stable_max, 'FM999990.000000') end;

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

  if found then return; end if;

  insert into public.notifications (
    employee_id, source, alert_key, parameter, title, message, type,
    current_value, ideal_range, recommendation, status, is_read, is_resolved,
    lifecycle_state, stable_reading_count
  ) values (
    null, 'sensor', alert_key_value, parameter_name,
    format('%s %s', parameter_name, direction_name),
    format(
      '%s five-minute average is %s at %s %s. Stable range: %s - %s %s.',
      parameter_name, lower(direction_name), measured_text, unit_name,
      stable_min_text, stable_max_text, unit_name
    ),
    severity_name,
    format('%s %s', measured_text, unit_name),
    format('%s - %s %s', stable_min_text, stable_max_text, unit_name),
    recommendation_text, 'unread', false, false, 'open', 0
  ) on conflict do nothing;
end;
$$;

drop function if exists public.record_notification_intervention(
  uuid, text, numeric, text, text, numeric, text, numeric
);

create function public.record_notification_intervention(
  notification_id_value uuid,
  parameter_value text,
  current_value_value numeric,
  current_status_value text,
  action_type_value text,
  amount_value numeric default null,
  notes_value text default '',
  reservoir_volume_l_value numeric default null
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  actor uuid := auth.uid();
  latest_history public.sensor_history%rowtype;
  action_id public.action_logs.id%type;
  affected text[];
  fixes_text text[];
  fixes_value public.action_logs.suggested_fixes%type;
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

  fixes_text := array[
    'Action: ' || action_type_value,
    case when amount_value is null then 'Amount: not recorded'
      else 'Amount: ' || amount_value || ' mL' end,
    case when coalesce(notes_value, '') <> ''
      then 'Notes: ' || notes_value else 'Notes: not recorded' end,
    'Notification: ' || notification_id_value::text
  ];
  if pg_typeof(fixes_value)::text = 'jsonb' then
    execute 'select to_jsonb($1::text[])' into fixes_value using fixes_text;
  elsif pg_typeof(fixes_value)::text = 'text[]' then
    execute 'select $1::text[]' into fixes_value using fixes_text;
  else
    raise exception 'Unsupported action_logs.suggested_fixes type: %',
      pg_typeof(fixes_value);
  end if;

  insert into public.action_logs (
    created_by, parameter, forecast_condition, horizon_hours,
    current_ph, current_ec, current_temp, suggested_fixes,
    notification_id, source, action_type, amount, amount_unit, notes,
    performed_at, affected_parameters, reservoir_volume_l,
    sensor_history_id_before
  ) values (
    actor,
    parameter_value,
    current_status_value,
    0,
    case when lower(parameter_value) in ('ph', 'ph level')
      then current_value_value else coalesce(latest_history.avg_ph, 0) end,
    case when lower(parameter_value) in ('ec', 'ec level')
      then current_value_value else coalesce(latest_history.avg_ec, 0) end,
    case when lower(parameter_value) in ('temperature', 'temp')
      then current_value_value else coalesce(latest_history.avg_temp, 0) end,
    fixes_value,
    notification_id_value,
    'notification_fix',
    action_type_value,
    amount_value,
    'mL',
    nullif(trim(notes_value), ''),
    now(),
    affected,
    reservoir_volume_l_value,
    latest_history.id
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

  return action_id::text;
end;
$$;

grant execute on function public.record_notification_intervention(
  uuid, text, numeric, text, text, numeric, text, numeric
) to authenticated;

-- Standalone fixes must be saved even when no notification is attached.
create or replace function public.record_manual_intervention(
  parameter_value text,
  current_value_value numeric,
  action_type_value text,
  amount_value numeric default null,
  notes_value text default '',
  reservoir_volume_l_value numeric default null
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  actor uuid := auth.uid();
  latest_history public.sensor_history%rowtype;
  action_id public.action_logs.id%type;
  normalized_parameter text := lower(trim(parameter_value));
  affected text[];
  fixes_text text[];
  fixes_value public.action_logs.suggested_fixes%type;
begin
  if actor is null then
    raise exception 'Authentication is required.';
  end if;
  if normalized_parameter not in ('ph', 'ec', 'temperature') then
    raise exception 'Unsupported intervention parameter.';
  end if;
  if trim(coalesce(action_type_value, '')) = '' then
    raise exception 'Action type is required.';
  end if;
  if amount_value < 0 or reservoir_volume_l_value < 0 then
    raise exception 'Amount and reservoir volume cannot be negative.';
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
    else array[normalized_parameter]
  end;

  fixes_text := array[
    'Action: ' || action_type_value,
    case when amount_value is null then 'Amount: not recorded'
      else 'Amount: ' || amount_value || ' mL' end,
    case when coalesce(notes_value, '') = '' then 'Notes: not recorded'
      else 'Notes: ' || notes_value end
  ];
  if pg_typeof(fixes_value)::text = 'jsonb' then
    execute 'select to_jsonb($1::text[])' into fixes_value using fixes_text;
  elsif pg_typeof(fixes_value)::text = 'text[]' then
    execute 'select $1::text[]' into fixes_value using fixes_text;
  else
    raise exception 'Unsupported action_logs.suggested_fixes type: %',
      pg_typeof(fixes_value);
  end if;

  insert into public.action_logs (
    created_by, parameter, forecast_condition, horizon_hours,
    current_ph, current_ec, current_temp, suggested_fixes,
    source, action_type, amount, amount_unit, notes,
    performed_at, affected_parameters, reservoir_volume_l,
    sensor_history_id_before
  ) values (
    actor, normalized_parameter, 'Manual intervention', 0,
    case when normalized_parameter = 'ph' then current_value_value
      else coalesce(latest_history.avg_ph, 0) end,
    case when normalized_parameter = 'ec' then current_value_value
      else coalesce(latest_history.avg_ec, 0) end,
    case when normalized_parameter = 'temperature' then current_value_value
      else coalesce(latest_history.avg_temp, 0) end,
    fixes_value,
    'manual_fix', action_type_value, amount_value, 'mL',
    nullif(trim(notes_value), ''), now(), affected,
    reservoir_volume_l_value, latest_history.id
  ) returning id into action_id;

  return action_id::text;
end;
$$;

grant execute on function public.record_manual_intervention(
  text, numeric, text, numeric, text, numeric
) to authenticated;

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
        when 'ph' then new.avg_ph
        else new.avg_ec
      end,
      actual_recorded_at = new.recorded_at,
      evaluated_at = now(),
      intervention_count = (
        select count(*)::integer
        from public.action_logs action
        where action.performed_at > prediction.baseline_recorded_at
          and action.performed_at <= new.recorded_at
          and (
            prediction.parameter = any(action.affected_parameters)
            or lower(action.parameter) = prediction.parameter
            or lower(action.parameter) = prediction.parameter || ' level'
          )
      ),
      evaluation_status = case when exists (
        select 1
        from public.action_logs action
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
  set evaluation_status = 'missing_actual',
      evaluated_at = now()
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
    else power(actual_value - predicted_value, 2) end as squared_error,
  intervention.action_type as intervention_action_type,
  intervention.performed_at as intervention_performed_at
from public.forecast_predictions prediction
left join lateral (
  select action.action_type, action.performed_at
  from public.action_logs action
  where action.performed_at > prediction.baseline_recorded_at
    and action.performed_at <= coalesce(
      prediction.actual_recorded_at, prediction.target_at
    )
    and (
      prediction.parameter = any(action.affected_parameters)
      or lower(action.parameter) = prediction.parameter
      or lower(action.parameter) = prediction.parameter || ' level'
    )
  order by action.performed_at
  limit 1
) intervention on true;

grant select on public.forecast_prediction_evaluations to authenticated;

-- Promote legacy resolved rows without reopening alerts with an action taken.
update public.notifications
set lifecycle_state = 'resolved'
where is_resolved = true
  and lifecycle_state = 'open';
