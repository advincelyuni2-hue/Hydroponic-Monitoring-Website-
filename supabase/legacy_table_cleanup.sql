-- REVIEW-ONLY legacy table cleanup checklist.
-- Do not uncomment DROP statements until the updated ESP32 firmware, Flutter
-- app, forecasting backend, realtime_setup.sql, and rbac_setup.sql are deployed.

-- Confirm no recent writers remain. A max timestamp that continues moving
-- means an older device or service is still using the legacy table.
select 'ph_readings' as table_name, count(*) as rows, max(recorded_at) as newest
from public.ph_readings
union all
select 'ec_readings', count(*), max(recorded_at) from public.ec_readings
union all
select 'temp_readings', count(*), max(recorded_at) from public.temp_readings;

-- Inspect optional tables only if they exist in the project:
-- select count(*), max(created_at) from public.critical_alerts;
-- select count(*) from public.history_logs;

-- Safe deletion candidates after backup and deployment verification:
-- drop table if exists public.critical_alerts;
-- drop table if exists public.history_logs;
-- drop table if exists public.ph_readings;
-- drop table if exists public.ec_readings;
-- drop table if exists public.temp_readings;

-- Keep these active tables:
-- sensor_history, notifications, parameter_configurations, profiles,
-- calibration_logs, action_logs, dismissed_action_logs, forecast_logs,
-- help_articles.
