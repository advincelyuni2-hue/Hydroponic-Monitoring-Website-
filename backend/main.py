import os
from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
import joblib
import numpy as np
from supabase import create_client, Client
import tensorflow as tf

app = FastAPI(title="Hydroponics Delta-LSTM Forecasting API")

allowed_origins = [
    origin.strip()
    for origin in os.getenv(
        "CORS_ORIGINS", "http://localhost,http://127.0.0.1"
    ).split(",")
    if origin.strip()
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Use the same project selected by the Flutter app; never commit credentials.
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv(
    "SUPABASE_PUBLISHABLE_KEY", os.getenv("SUPABASE_ANON_KEY", "")
)
supabase: Client | None = (
    create_client(SUPABASE_URL, SUPABASE_KEY)
    if SUPABASE_URL and SUPABASE_KEY
    else None
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Load models and scalers
ph_model = tf.keras.models.load_model(
    os.path.join(BASE_DIR, "ph_lstm_model.h5"), compile=False
)
ec_model = tf.keras.models.load_model(
    os.path.join(BASE_DIR, "ec_lstm_model.h5"), compile=False
)

kmeans_model = joblib.load(os.path.join(BASE_DIR, "kmeans_model.joblib"))
scaler_lstm = joblib.load(os.path.join(BASE_DIR, "scaler_lstm.joblib"))
scaler_ph_delta = joblib.load(os.path.join(BASE_DIR, "scaler_ph_delta.joblib"))
scaler_ec_delta = joblib.load(os.path.join(BASE_DIR, "scaler_ec_delta.joblib"))
scaler_kmeans = joblib.load(os.path.join(BASE_DIR, "scaler_kmeans.joblib"))


def fetch_historical_sequence():
    """Build a chronological 24-step sequence from the sensor reading tables."""
    try:
        if supabase is None:
            raise RuntimeError("Supabase environment variables are not configured")

        def values(table: str, fallback: float):
            response = (
                supabase.from_(table)
                .select("value, recorded_at")
                .eq("is_average", False)
                .order("recorded_at", desc=True)
                .limit(24)
                .execute()
            )
            result = [float(row["value"]) for row in reversed(response.data or [])]
            if not result:
                return [fallback] * 24
            return [result[0]] * (24 - len(result)) + result[-24:]

        ph_values = values("ph_readings", 6.5)
        ec_values = values("ec_readings", 1.5)
        temp_values = values("temp_readings", 24.0)
        return np.array(
            [
                [ph_values[i], ec_values[i] * 500.0, temp_values[i]]
                for i in range(24)
            ]
        )

    except Exception as e:
        print(f"Error fetching sensor sequence: {e}")
        return np.tile([6.5, 750.0, 24.0], (24, 1))


@app.get("/health")
def health():
    return {"status": "ok", "supabase_configured": supabase is not None}
        
@app.get("/api/predict/forecast")
def predict_forecast(
    parameter: str = Query("ph", description="ph or ec"),
    ph: float = Query(6.5),
    ec: float = Query(1.5),
    temp: float = Query(24.0),
    horizon: int = Query(12, description="Active UI horizon: 4, 8, or 12"),
):
    try:
        is_ph = parameter.lower() == "ph"
        model = ph_model if is_ph else ec_model
        scaler_delta = scaler_ph_delta if is_ph else scaler_ec_delta
        base_val = ph if is_ph else ec

        # 1. Fetch real 24-step historical sequence matrix from Supabase
        raw_sequence = fetch_historical_sequence()  # Shape: (24, 3)

        # Update the final sequence entry with the active live parameters
        raw_sequence[-1] = [ph, ec * 500.0, temp]

        # 2. Add Velocity feature diff(1) in column 3
        padded_seq = np.zeros((24, 8))
        padded_seq[:, :3] = raw_sequence
        padded_seq[1:, 3] = raw_sequence[1:, 0] - raw_sequence[:-1, 0]

        # 3. Scale input sequence
        scaled_seq = scaler_lstm.transform(padded_seq)

        # 4. Reshape for LSTM: (1 sample, 24 timesteps, 8 features)
        lstm_input = np.expand_dims(scaled_seq, axis=0)

        # 5. Model Inference -> Generates [4h Delta, 8h Delta, 12h Delta]
        scaled_deltas = model.predict(lstm_input)

        if hasattr(scaler_delta, "inverse_transform"):
            unscaled_deltas = scaler_delta.inverse_transform(scaled_deltas)[0]
        else:
            unscaled_deltas = scaled_deltas[0]

        delta_4h = float(unscaled_deltas[0])
        delta_8h = float(unscaled_deltas[1])
        delta_12h = float(unscaled_deltas[2])

        # Convert PPM delta back to mS/cm if parameter is EC
        if not is_ph:
            delta_4h /= 500.0
            delta_8h /= 500.0
            delta_12h /= 500.0

        val_4h = base_val + delta_4h
        val_8h = base_val + delta_8h
        val_12h = base_val + delta_12h

        # 6. Return dynamic trajectory mapped to selected UI pill horizon
        if horizon == 4:
            predictions = [
                {"hour": 1.3, "value": round(base_val + (delta_4h * 0.33), 2)},
                {"hour": 2.6, "value": round(base_val + (delta_4h * 0.66), 2)},
                {"hour": 4.0, "value": round(val_4h, 2)},
            ]
        elif horizon == 8:
            predictions = [
                {"hour": 2.6, "value": round(base_val + (delta_4h * 0.66), 2)},
                {"hour": 5.3, "value": round(val_4h, 2)},
                {"hour": 8.0, "value": round(val_8h, 2)},
            ]
        else:  # 12h horizon -> Displays all 3 model outputs
            predictions = [
                {"hour": 4.0, "value": round(val_4h, 2)},
                {"hour": 8.0, "value": round(val_8h, 2)},
                {"hour": 12.0, "value": round(val_12h, 2)},
            ]

        raw_features = np.array([[ph, ec, temp]])
        scaled_kmeans_features = scaler_kmeans.transform(raw_features)
        cluster_id = int(kmeans_model.predict(scaled_kmeans_features)[0])

        return {
            "parameter": parameter,
            "horizon": horizon,
            "predictions": predictions,
            "cluster_id": cluster_id,
        }

    except Exception as e:
        base_val = ph if parameter.lower() == "ph" else ec
        step = horizon / 3.0
        return {
            "parameter": parameter,
            "horizon": horizon,
            "predictions": [
                {"hour": round(step, 1), "value": round(base_val + 0.1, 2)},
                {"hour": round(step * 2, 1), "value": round(base_val + 0.2, 2)},
                {"hour": float(horizon), "value": round(base_val + 0.3, 2)},
            ],
            "error_fallback": str(e),
        }
