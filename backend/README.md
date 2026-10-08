# Forecasting backend

The Flutter forecasting screen calls this FastAPI service. It uses the model
artifacts in this directory and reads recent five-minute averages from the same
Supabase project as the app.

1. Create and activate a Python virtual environment.
2. Install dependencies with `pip install -r requirements.txt`.
3. Configure `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` in the backend
   environment. Keep the service-role key on the server and never expose it to
   Flutter or the browser. Optional settings are `FORECAST_MODEL_VERSION`
   (stored with each prediction) and `SENSOR_OFFLINE_AFTER_MINUTES` (defaults
   to `10`).
4. Export those environment variables, then run:

   ```text
   uvicorn main:app --reload --host 127.0.0.1 --port 8000
   ```

The health check is available at `http://127.0.0.1:8000/health`. Flutter uses
that host by default; override it with
`--dart-define=FORECAST_API_URL=http://HOST:8000/api/predict/forecast` when the
backend runs on another machine or when testing on a physical device.

Each successful forecast stores its 4-, 8-, and 12-hour predictions in
`forecast_predictions`. New `sensor_history` rows later attach the actual
value; predictions affected by a logged intervention are marked separately and
excluded from the accuracy score. If the newest sensor row is older than the
offline threshold, the endpoint returns HTTP 409 instead of generating or
storing a forecast.
