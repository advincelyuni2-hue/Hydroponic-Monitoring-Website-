-- Read-only checks after forecast_intervention_setup.sql.
select to_regclass('public.forecast_predictions') as forecast_predictions;

select
  to_regprocedure('public.record_notification_intervention(uuid,text,numeric,text,text,numeric,text,numeric)')
    as notification_intervention_function,
  to_regprocedure('public.record_manual_intervention(text,numeric,text,numeric,text,numeric)')
    as manual_intervention_function;

select
  table_name,
  column_name,
  data_type,
  udt_name
from information_schema.columns
where table_schema = 'public'
  and (
    (table_name = 'sensor_history' and column_name = 'id')
    or (table_name = 'forecast_predictions'
      and column_name in ('baseline_history_id', 'actual_history_id'))
    or (table_name = 'action_logs'
      and column_name in ('id', 'sensor_history_id_before', 'suggested_fixes'))
    or (table_name = 'notifications'
      and column_name = 'action_log_id')
  )
order by table_name, column_name;

select parameter, horizon_hours, evaluation_status, count(*)
from public.forecast_predictions
group by parameter, horizon_hours, evaluation_status
order by parameter, horizon_hours, evaluation_status;

select
  parameter, horizon_hours, baseline_recorded_at, target_at,
  predicted_value, actual_value, evaluation_status,
  absolute_error, percentage_error, intervention_count,
  intervention_action_type, intervention_performed_at
from public.forecast_prediction_evaluations
order by target_at desc
limit 30;

select
  id, parameter, lifecycle_state, stable_reading_count,
  action_taken_at, recovery_started_at, is_resolved, resolved_at
from public.notifications
where source = 'sensor'
order by timestamp desc
limit 30;

select
  id, notification_id, source, action_type, amount, amount_unit,
  affected_parameters, performed_at, sensor_history_id_before
from public.action_logs
where source = 'notification_fix'
order by performed_at desc
limit 30;

select
  id, created_by, parameter, source, action_type, amount,
  reservoir_volume_l, affected_parameters, performed_at
from public.action_logs
where source = 'manual_fix'
order by performed_at desc
limit 30;
