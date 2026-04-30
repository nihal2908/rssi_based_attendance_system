from fastapi import FastAPI, Request
from fastapi.responses import FileResponse
import numpy as np
import tensorflow as tf
import os
import time

# ------------------ FastAPI Init ------------------
app = FastAPI()

os.makedirs("models", exist_ok=True)

# ------------------ TRAIN + CONVERT ------------------
@app.post("/train/{classroom_id}")
async def train_model(classroom_id: str, request: Request):
    data = await request.json()

    inside = data.get("inside", [])
    outside = data.get("outside", [])

    if not inside or not outside:
        return {"error": "Inside and Outside data required"}

    # ------------------ VALIDATION ------------------
    all_data = inside + outside

    input_dim = len(all_data[0])

    for sample in all_data:
        if len(sample) != input_dim:
            return {
                "error": f"Inconsistent input size. Expected {input_dim}, got {len(sample)}"
            }

    # ------------------ PREPARE DATA ------------------
    X = []
    y = []

    for rssi in inside:
        X.append(rssi)
        y.append(1)

    for rssi in outside:
        X.append(rssi)
        y.append(0)

    X = np.array(X, dtype=np.float32)
    y = np.array(y, dtype=np.float32)

    # OPTIONAL: normalize
    X = X / 100.0

    # ------------------ MODEL ------------------
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(input_dim,)),  # ✅ dynamic input
        tf.keras.layers.Dense(16, activation='relu'),
        tf.keras.layers.Dense(8, activation='relu'),
        tf.keras.layers.Dense(1, activation='sigmoid')
    ])

    model.compile(
        optimizer='adam',
        loss='binary_crossentropy',
        metrics=['accuracy']
    )

    model.fit(X, y, epochs=30, verbose=0)

    # ------------------ CONVERT TO TFLITE ------------------
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()

    model_path = f"models/{classroom_id}.tflite"

    with open(model_path, "wb") as f:
        f.write(tflite_model)

    return {
        "message": "Model trained and converted to TFLite",
        "input_dim": input_dim,
        "modelPath": model_path
    }

# ------------------ DOWNLOAD MODEL ------------------
@app.get("/model/{classroom_id}")
def get_model(classroom_id: str):
    model_path = f"models/{classroom_id}.tflite"

    if not os.path.exists(model_path):
        return {"error": "Model not found"}

    return FileResponse(
        path=model_path,
        filename=f"{classroom_id}.tflite",
        media_type="application/octet-stream"
    )