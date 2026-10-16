-- Run after forecast_intervention_setup.sql. Manual logs may describe an action
-- performed earlier than the time it was entered into the web app.

create or replace function public.reconcile_dated_intervention_forecasts()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Existing evaluated rows were already processed by the sensor-history
  -- trigger, so backdated actions need a second pass. Preserve pending,
  -- missing-actual and calibration-excluded statuses.
  update public.forecast_predictions prediction
  set intervention_count = (
        select count(*)::integer
        from public.action_logs action
        where action.performed_at > prediction.baseline_recorded_at
          and action.performed_at <= prediction.actual_recorded_at
          and (
            prediction.parameter = any(action.affected_parameters)
            or lower(action.parameter) = prediction.parameter
            or lower(action.parameter) = prediction.parameter || ' level'
          )
      ),
      evaluation_status = 'intervened'
  where prediction.evaluation_status in ('evaluated', 'intervened')
    and prediction.actual_recorded_at is not null
    and new.performed_at > prediction.baseline_recorded_at
    and new.performed_at <= prediction.actual_recorded_at
    and (
      prediction.parameter = any(new.affected_parameters)
      or lower(new.parameter) = prediction.parameter
      or lower(new.parameter) = prediction.parameter || ' level'
    );
  return new;
end;
$$;

drop trigger if exists reconcile_dated_intervention_forecasts
  on public.action_logs;
create trigger reconcile_dated_intervention_forecasts
after update of performed_at on public.action_logs
for each row
when (old.performed_at is distinct from new.performed_at)
execute function public.reconcile_dated_intervention_forecasts();

-- Keep the existing six-argument RPC for older clients. This seven-argument
-- wrapper supplies an audited action time, while the original RPC continues
-- to validate and save the action itself.
create or replace function public.record_manual_intervention_at(
  parameter_value text,
  current_value_value numeric,
  action_type_value text,
  amount_value numeric,
  notes_value text,
  reservoir_volume_l_value numeric,
  performed_at_value timestamptz
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  action_id_text text;
  historical_history public.sensor_history%rowtype;
  updated_action_id text;
  normalized_parameter text := lower(trim(parameter_value));
begin
  if performed_at_value is null or performed_at_value > now() + interval '1 minute' then
    raise exception 'Enter an action date and time that is not in the future.';
  end if;

  action_id_text := public.record_manual_intervention(
    parameter_value, current_value_value, action_type_value,
    amount_value, notes_value, reservoir_volume_l_value
  );

  select * into historical_history
  from public.sensor_history
  where recorded_at <= performed_at_value
  order by recorded_at desc
  limit 1;

  update public.action_logs
  set performed_at = performed_at_value,
      sensor_history_id_before = historical_history.id,
      current_ph = case when normalized_parameter = 'ph'
        then current_value_value else coalesce(historical_history.avg_ph, 0) end,
      current_ec = case when normalized_parameter = 'ec'
        then current_value_value else coalesce(historical_history.avg_ec, 0) end,
      current_temp = case when normalized_parameter = 'temperature'
        then current_value_value else coalesce(historical_history.avg_temp, 0) end
  where id::text = action_id_text and created_by = auth.uid()
  returning id::text into updated_action_id;

  if updated_action_id is null then
    raise exception 'The intervention could not be timestamped.';
  end if;
  return updated_action_id;
end;
$$;

revoke all on function public.record_manual_intervention_at(
  text, numeric, text, numeric, text, numeric, timestamptz
) from public;
grant execute on function public.record_manual_intervention_at(
  text, numeric, text, numeric, text, numeric, timestamptz
) to authenticated;
