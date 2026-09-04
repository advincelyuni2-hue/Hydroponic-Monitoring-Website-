-- Run once in the Supabase SQL Editor.
-- The Flutter app currently uses a publishable key without a real auth session,
-- so these tables need read access for the anon role.

grant select on table public.ph_readings to anon, authenticated;
grant select on table public.ec_readings to anon, authenticated;
grant select on table public.temp_readings to anon, authenticated;
grant select on table public.sensor_history to anon, authenticated;

drop policy if exists "Dashboard can read pH readings" on public.ph_readings;
create policy "Dashboard can read pH readings"
on public.ph_readings for select to anon, authenticated using (true);

drop policy if exists "Dashboard can read EC readings" on public.ec_readings;
create policy "Dashboard can read EC readings"
on public.ec_readings for select to anon, authenticated using (true);

drop policy if exists "Dashboard can read temperature readings" on public.temp_readings;
create policy "Dashboard can read temperature readings"
on public.temp_readings for select to anon, authenticated using (true);

drop policy if exists "Dashboard can read sensor history" on public.sensor_history;
create policy "Dashboard can read sensor history"
on public.sensor_history for select to anon, authenticated using (true);

do $$
declare
  table_name text;
begin
  foreach table_name in array array['ph_readings', 'ec_readings', 'temp_readings']
  loop
    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = table_name
    ) then
      execute format(
        'alter publication supabase_realtime add table public.%I',
        table_name
      );
    end if;
  end loop;
end $$;
