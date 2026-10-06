import os
import json
import traceback
import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import tensorflow as tf
from supabase import create_client, Client

@tf.keras.utils.register_keras_serializable()
def se_block(x, reduction=4):
    ch = x.shape[-1]
    s = tf.keras.layers.GlobalAveragePooling1D()(x)
    s = tf.keras.layers.Dense(max(ch // reduction, 4), activation="relu")(s)
    s = tf.keras.layers.Dense(ch, activation="sigmoid")(s)
    s = tf.keras.layers.Reshape((1, ch))(s)
    return tf.keras.layers.Multiply()([x, s])

app = FastAPI(title="Hydroponics Delta-LSTM Multi-Horizon Forecasting API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health_check():
    return {"status": "ok"}

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

# Load Config & Artifacts
with open(os.path.join(BASE_DIR, "model_config.json"), "r") as f:
    model_config = json.load(f)

ph_model = tf.keras.models.load_model(
    os.path.join(BASE_DIR, "ph_forecaster.keras"),
    custom_objects={"se_block": se_block},
    compile=False
)
ec_model = tf.keras.models.load_model(
    os.path.join(BASE_DIR, "ec_forecaster.keras"),
    custom_objects={"se_block": se_block},
    compile=False
)

feature_scaler = joblib.load(os.path.join(BASE_DIR, "feature_scaler.joblib"))
ph_delta_scaler = joblib.load(os.path.join(BASE_DIR, "ph_delta_scaler.joblib"))
ec_delta_scaler = joblib.load(os.path.join(BASE_DIR, "ec_delta_scaler.joblib"))


def get_resilient_sequence(live_ph: float, live_ec: float, live_temp: float) -> pd.DataFrame:
    """Builds a guaranteed 96-step 15-min downsampled DataFrame, filling missing historical points seamlessly."""
    end_time = pd.Timestamp.now(tz="UTC")
    times = pd.date_range(end=end_time, periods=96, freq="15min")

    df = pd.DataFrame(index=times)
    df["ph"] = live_ph
    df["ec"] = live_ec
    df["temp"] = live_temp

    if supabase is None:
        return df

    def fetch_records(table_name: str, col_name: str):
        try:
            res = (
                supabase.from_(table_name)
                .select("value, recorded_at")
                .eq("is_average", False)
                .order("recorded_at", desc=True)
                .limit(288)
                .execute()
            )
            data = res.data or []
            if not data:
                return None
            sub_df = pd.DataFrame(data)
            sub_df["recorded_at"] = pd.to_datetime(sub_df["recorded_at"], utc=True)
            sub_df[col_name] = sub_df["value"].astype(float)
            return sub_df[["recorded_at", col_name]].sort_values("recorded_at").set_index("recorded_at")
        except Exception:
            return None

    ph_df = fetch_records("ph_readings", "ph")
    ec_df = fetch_records("ec_readings", "ec")
    temp_df = fetch_records("temp_readings", "temp")

    if ph_df is not None and not ph_df.empty:
        df["ph"] = ph_df["ph"].reindex(df.index, method="nearest").fillna(live_ph)
    if ec_df is not None and not ec_df.empty:
        df["ec"] = ec_df["ec"].reindex(df.index, method="nearest").fillna(live_ec)
    if temp_df is not None and not temp_df.empty:
        df["temp"] = temp_df["temp"].reindex(df.index, method="nearest").fillna(live_temp)

    # Set current live values at t0
    df.iloc[-1, df.columns.get_loc("ph")] = live_ph
    df.iloc[-1, df.columns.get_loc("ec")] = live_ec
    df.iloc[-1, df.columns.get_loc("temp")] = live_temp

    return df


def compute_21_features(df: pd.DataFrame) -> np.ndarray:
    """Computes exact 21 features in the exact column order specified by model_config.json."""
    f = pd.DataFrame(index=df.index)
    f["ph"] = df["ph"]
    f["ec"] = df["ec"]
    f["temp"] = df["temp"]

    f["std_ph"] = df["ph"].rolling(12, min_periods=1).std().fillna(0.0)
    f["std_ec"] = df["ec"].rolling(12, min_periods=1).std().fillna(0.0)
    f["std_temp"] = df["temp"].rolling(12, min_periods=1).std().fillna(0.0)

    f["ph_spread"] = 0.0
    f["ec_spread"] = 0.0

    for lag, name in [(12, "1h"), (72, "6h")]:
        f[f"ph_d_{name}"] = df["ph"] - df["ph"].shift(lag).bfill()
        f[f"ec_d_{name}"] = df["ec"] - df["ec"].shift(lag).bfill()
        f[f"temp_d_{name}"] = df["temp"] - df["temp"].shift(lag).bfill()

    f["ph_std_1h"] = df["ph"].rolling(12, min_periods=1).std().fillna(0.0)
    f["ec_std_1h"] = df["ec"].rolling(12, min_periods=1).std().fillna(0.0)
    f["ec_trend_ratio"] = df["ec"].rolling(12, min_periods=1).mean() / (
        df["ec"].rolling(72, min_periods=1).mean() + 1e-6
    )

    local_offset = model_config.get("local_utc_offset_h", 8)
    local_time = df.index + pd.to_timedelta(local_offset, unit="h")
    hrs = np.array([t.hour for t in local_time])
    mins = np.array([t.minute for t in local_time])
    hours = hrs + mins / 60.0
    f["hour_sin"] = np.sin(2 * np.pi * hours / 24.0)
    f["hour_cos"] = np.cos(2 * np.pi * hours / 24.0)

    dph = df["ph"].diff().abs().fillna(0.0)
    dec = df["ec"].diff().abs().fillna(0.0)
    iv = ((dph > 0.5) | (dec > 0.1)).astype(float)
    f["intervention"] = iv.rolling(3, min_periods=1).max()

    pos = np.arange(len(df), dtype=float)
    last = pd.Series(np.where(iv.values == 1.0, pos, np.nan)).ffill().values
    since = np.where(np.isnan(last), 288.0, np.minimum(pos - last, 288.0))
    f["steps_since_intervention"] = since / 288.0

    expected_cols = model_config["features"]
    return f[expected_cols].values.astype(np.float32)


@app.get("/api/predict/forecast")
def predict_forecast(
    parameter: str = Query("ph", description="ph or ec"),
    ph: float = Query(...),
    ec: float = Query(...),
    temp: float = Query(...),
    horizon: int = Query(12, description="4, 8, or 12 hours"),
):
    try:
        is_ph = parameter.lower() == "ph"
        model = ph_model if is_ph else ec_model
        delta_scaler = ph_delta_scaler if is_ph else ec_delta_scaler
        base_val = ph if is_ph else ec

        # 1. Fetch guaranteed 96-step sequence
        grid_df = get_resilient_sequence(ph, ec, temp)

        # 2. Compute 21 input features
        feature_matrix = compute_21_features(grid_df)

        # 3. Transform & Clip Features
        scaled_features = feature_scaler.transform(feature_matrix)
        feature_clip = model_config.get("feature_clip", 5.0)
        clipped_features = np.clip(scaled_features, -feature_clip, feature_clip)

        # 4. Reshape for Keras Model: (1 sample, 96 timesteps, 21 features)
        model_input = np.expand_dims(clipped_features, axis=0)

        # 5. Model Inference (handles both dict and list return types)
        preds = model.predict(model_input, verbose=0)

        if isinstance(preds, dict):
            reg_output = preds["reg_output"]
            state_output = preds["state_output"]
        elif isinstance(preds, list):
            reg_output = preds[0]
            state_output = preds[1]
        else:
            reg_output = preds
            state_output = np.array([[1.0, 0.0, 0.0]])

        # Inverse transform multi-horizon deltas (4h, 8h, 12h)
        unscaled_deltas = delta_scaler.inverse_transform(reg_output)[0]

        delta_4h = float(unscaled_deltas[0])
        delta_8h = float(unscaled_deltas[1])
        delta_12h = float(unscaled_deltas[2])

        val_4h = base_val + delta_4h
        val_8h = base_val + delta_8h
        val_12h = base_val + delta_12h

        # 6. Build UI Trajectory Points
        if horizon == 4:
            predictions = [
                {"hour": 1.3, "value": round(base_val + (delta_4h * 0.33), 2), "is_predicted": True},
                {"hour": 2.6, "value": round(base_val + (delta_4h * 0.66), 2), "is_predicted": True},
                {"hour": 4.0, "value": round(val_4h, 2), "is_predicted": True},
            ]
        elif horizon == 8:
            predictions = [
                {"hour": 2.6, "value": round(base_val + (delta_4h * 0.66), 2), "is_predicted": True},
                {"hour": 5.3, "value": round(val_4h, 2), "is_predicted": True},
                {"hour": 8.0, "value": round(val_8h, 2), "is_predicted": True},
            ]
        else:
            predictions = [
                {"hour": 4.0, "value": round(val_4h, 2), "is_predicted": True},
                {"hour": 8.0, "value": round(val_8h, 2), "is_predicted": True},
                {"hour": 12.0, "value": round(val_12h, 2), "is_predicted": True},
            ]

        state_idx = int(np.argmax(state_output[0]))
        state_labels = ["Stable", "Warning", "Critical"]
        predicted_state = state_labels[state_idx]

        return {
            "parameter": parameter,
            "horizon": horizon,
            "predictions": predictions,
            "predicted_state": predicted_state,
            "val_4h": round(val_4h, 3),
            "val_8h": round(val_8h, 3),
            "val_12h": round(val_12h, 3),
        }

    except Exception as e:
        print("--- FORECASTING INFERENCE ERROR TRACEBACK ---")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
