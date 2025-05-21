# Niveles/4/api/app/main.py
from fastapi import FastAPI
from pydantic import BaseModel
import numpy as np
import pickle
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
from fastapi.responses import Response

# Cargar modelo
with open("app/model.pkl", "rb") as f:
    model = pickle.load(f)

# Prometheus métrica
predict_counter = Counter("predict_requests_total", "Total de peticiones al endpoint /predict")

# FastAPI app
app = FastAPI()

class InputData(BaseModel):
    data: list[list[float]]

@app.post("/predict")
def predict(input_data: InputData):
    predict_counter.inc()
    data = np.array(input_data.data)
    preds = model.predict(data).tolist()
    return {"predictions": preds}

@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
