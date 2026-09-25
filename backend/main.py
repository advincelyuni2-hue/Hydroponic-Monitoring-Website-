import os
from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
import joblib
import numpy as np
from supabase import create_client, Client
import tensorflow as tf

app = FastAPI(title="Hydroponics Delta-LSTM Forecasting API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Connect to your Supabase instance
SUPABASE_URL = "https://rhgcxqgcxnaxgwksdyks.supabase.co"
SUPABASE_KEY = "sb_publishable_JCVLqWnQuQKzrnFGWUDJcQ_Lax526-E"
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

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
    """Queries the past 24 summary logs from sensor_history in strict chronological order."""
    try:
        # 1. Get the 24 most recent records
        response = (
            supabase.from_("sensor_history")
            .select("latest_ph, latest_ec, latest_temp, recorded_at")
            .order("recorded_at", desc=True)
            .limit(24)
            .execute()
        )

        rows = response.data

        if not rows:
            # Safe fallback sequence if the table is empty
            return np.tile([6.5, 750.0, 24.0], (24, 1))

        # Handle padding if there are fewer than 24 historical records
        if len(rows) < 24:
            oldest_available = rows[-1]
            padding_count = 24 - len(rows)
            rows = rows + [oldest_available] * padding_count

        # 2. Reverse so sequence flows chronologically: Past -> Present
        rows.reverse()

        # 3. Build sequence matrix [pH, EC_in_PPM, Temperature]
        sequence = []
        for r in rows:
            ph_val = (
                float(r["latest_ph"]) if r["latest_ph"] is not None else 6.5
            )
            ec_ms = float(r["latest_ec"]) if r["latest_ec"] is not None else 1.5
            ec_ppm = ec_ms * 500.0  # 1.0 mS/cm = 500 PPM scale
            temp_val = (
                float(r["latest_temp"])
                if r["latest_temp"] is not None
                else 24.0
            )

            sequence.append([ph_val, ec_ppm, temp_val])

        return np.array(sequence)  # Shape: (24, 3)

    except Exception as e:
        print(f"Error fetching sensor_history sequence: {e}")
        return np.tile([6.5, 750.0, 24.0], (24, 1))
        
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