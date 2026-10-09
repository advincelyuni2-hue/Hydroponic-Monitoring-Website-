# Guided calibration setup

1. Apply `supabase/rbac_setup.sql` (if not already installed), then run
   `supabase/calibration_setup.sql` in the same Supabase project used by the
   website and ESP32. The second script adds live samples, sessions, points,
   calibration coefficients, and the maintenance gate.
2. Flash `arduino/sketch_aug12a_final_updated/sketch_aug12a_final_updated.ino`
   to the existing ESP32. The original five-minute history upload path remains;
   `CALIBRATION_MODE` is now `false` so the web app starts a session dynamically.
   Install the existing DHT and OLED libraries and the ESP32 board package.
3. Open History Logs → Calibration logs → Start Calibration while signed in.
   The operator name and user ID come from the signed-in profile, not a free-text
   field. Only that operator (or an admin) can finish/cancel their session.
4. For pH, capture fresh pH 7.00 and then pH 4.00. For the Gravity analog TDS
   path, capture 1413 µS/cm at a measured solution temperature of 24–26 °C.
   The 84 µS/cm bottle is available as an optional verification point; it does
   not change the TDS coefficient until the board SKU/range is confirmed.
5. After placing the probe in a standard, click **Start observing**. The web app
   polls raw ESP32 voltage samples and automatically saves the point when six
   readings spanning at least 45 seconds pass the starting variation
   limit (pH: 0.012 V; TDS: 0.020 V). These are engineering starting values;
   validate and tune them with the physical probes. Rinse-water/transfer
   readings are never captured. Re-click Start observing after each transfer.
6. Rinse and return the probe to the reservoir before confirming Finish. The
   ESP32 and database pause normal history during calibration and for one minute
   afterward; the ESP32 resets its five-minute sample buffer. Existing pending
   forecasts are retained as `calibration_excluded` and are not scored.

The ESP32 stores completed pH voltages or the 1413-standard TDS factor in NVS
and reports its applied coefficient version back to Supabase. The history log
shows `Pending device` until that report arrives; reports must not call it a
successful calibration before then. The firmware continues using the saved
values after restart. Until the first web-guided TDS session,
the previous EC formula remains the fallback. The TDS-derived EC display uses
the manufacturer's approximate 0.5 ppm/µS relationship at 25 °C; the DHT22 is
an **air** sensor and does not compensate nutrient-solution temperature. Verify
the exact Gravity module before treating derived EC as precision data.

Wi-Fi credentials are read by the ESP32 sketch; setting them as Render
environment variables will **not** configure the ESP32. Only the model service
needs its Supabase server-side environment variables on Render. Do not add a
Supabase service-role key to the Flutter web build or the ESP32.
