-- Function-only alert hotfix. Run forecast_intervention_setup.sql first so the
-- lifecycle columns exist. Safe to run after stopping ESP32 uploads and
-- closing active dashboard tabs.

set lock_timeout = '10s';
set statement_timeout = '60s';

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

  direction_name := case
    when measured_value < stable_min then 'Low'
    else 'High'
  end;
  severity_name := case
    when measured_value < stable_min - warning_margin
      or measured_value > stable_max + warning_margin then 'critical'
    else 'warning'
  end;
  recommendation_text := case
    when measured_value < stable_min then low_recommendation
    else high_recommendation
  end;
  alert_key_value := format(
    'sensor_history:%s:%s',
    parameter_key,
    lower(direction_name)
  );
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
        parameter_name,
        lower(direction_name),
        measured_text,
        unit_name,
        stable_min_text,
        stable_max_text,
        unit_name
      ),
      type = severity_name,
      current_value = format('%s %s', measured_text, unit_name),
      ideal_range = format(
        '%s - %s %s',
        stable_min_text,
        stable_max_text,
        unit_name
      ),
      recommendation = recommendation_text,
      timestamp = now(),
      stable_reading_count = 0,
      recovery_started_at = null,
      lifecycle_state = case
        when action_log_id is null then 'open' else 'action_taken'
      end,
      status = case
        when type is distinct from severity_name then 'unread'
        else status
      end,
      is_read = case
        when type is distinct from severity_name then false
        else is_read
      end
  where alert_key = alert_key_value
    and is_resolved = false;

  if found then
    return;
  end if;

  insert into public.notifications (
    employee_id,
    source,
    alert_key,
    parameter,
    title,
    message,
    type,
    current_value,
    ideal_range,
    recommendation,
    status,
    is_read,
    is_resolved,
    lifecycle_state,
    stable_reading_count
  ) values (
    null,
    'sensor',
    alert_key_value,
    parameter_name,
    format('%s %s', parameter_name, direction_name),
    format(
      '%s five-minute average is %s at %s %s. Stable range: %s - %s %s.',
      parameter_name,
      lower(direction_name),
      measured_text,
      unit_name,
      stable_min_text,
      stable_max_text,
      unit_name
    ),
    severity_name,
    format('%s %s', measured_text, unit_name),
    format(
      '%s - %s %s',
      stable_min_text,
      stable_max_text,
      unit_name
    ),
    recommendation_text,
    'unread',
    false,
    false,
    'open',
    0
  )
  on conflict do nothing;
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
    coalesce(
      (select ph_min from public.parameter_configurations where id = 1),
      5.5
    ) as ph_min,
    coalesce(
      (select ph_max from public.parameter_configurations where id = 1),
      6.5
    ) as ph_max,
    coalesce(
      (select ec_min from public.parameter_configurations where id = 1),
      1.2
    ) as ec_min,
    coalesce(
      (select ec_max from public.parameter_configurations where id = 1),
      1.8
    ) as ec_max
  into config;

  perform public.apply_sensor_alert(
    'ph',
    'pH Level',
    new.avg_ph::numeric,
    config.ph_min,
    config.ph_max,
    0.5,
    'pH',
    'Add pH-up solution gradually, circulate the solution, and verify the next five-minute average.',
    'Add pH-down solution gradually, circulate the solution, and verify the next five-minute average.'
  );

  perform public.apply_sensor_alert(
    'ec',
    'EC Level',
    new.avg_ec::numeric,
    config.ec_min,
    config.ec_max,
    0.5,
    'mS/cm',
    'Check the nutrient mixture and replenish nutrients gradually, then verify the next five-minute average.',
    'Check water level and concentration; dilute gradually with clean water, then verify the next five-minute average.'
  );

  perform public.apply_sensor_alert(
    'temp',
    'Temperature',
    new.avg_temp::numeric,
    18,
    24,
    5,
    '°C',
    'Inspect the heater and environment, raise temperature gradually, and verify the next five-minute average.',
    'Improve cooling or ventilation, inspect the reservoir, and verify the next five-minute average.'
  );

  return new;
end;
$$;

select
  routine_name,
  data_type
from information_schema.routines
where routine_schema = 'public'
  and routine_name in ('apply_sensor_alert', 'evaluate_five_minute_alerts')
order by routine_name;
