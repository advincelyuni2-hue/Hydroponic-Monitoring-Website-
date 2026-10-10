-- Safe, idempotent indexes for existing deployments.
-- Run once in the Supabase SQL Editor. New installations receive the same
-- indexes through rbac_setup.sql.

create index if not exists notifications_active_created_at_idx
on public.notifications (created_at desc)
where is_resolved = false;

create index if not exists notifications_active_sensor_parameter_idx
on public.notifications (parameter)
where source = 'sensor' and is_resolved = false;
