# Forecasting backend

The Flutter forecasting screen calls this FastAPI service. It uses the model
artifacts in this directory and reads recent raw sensor values from the same
Supabase project as the app.

1. Create and activate a Python virtual environment.
2. Install dependencies with `pip install -r requirements.txt`.
3. Copy `.env.example` to `.env` and supply the same Supabase URL and
   publishable key used by Flutter.
4. Export those environment variables, then run:

   ```text
   uvicorn main:app --reload --host 127.0.0.1 --port 8000
   ```

The health check is available at `http://127.0.0.1:8000/health`. Flutter uses
that host by default; override it with
`--dart-define=FORECAST_API_URL=http://HOST:8000/api/predict/forecast` when the
backend runs on another machine or when testing on a physical device.
