from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Any, Dict
import os
import numpy as np

import onnxruntime as ort

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

HERE = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.abspath(os.path.join(HERE, "..", "assets", "models", "ict"))
MODEL_1M = os.path.join(MODEL_DIR, "ict_1m.onnx")
MODEL_5M = os.path.join(MODEL_DIR, "ict_5m.onnx")

_sessions: Dict[str, ort.InferenceSession] = {}

def _load(tf: str) -> ort.InferenceSession:
    path = MODEL_1M if tf == "1m" else MODEL_5M
    if not os.path.exists(path):
        raise FileNotFoundError(f"Model not found: {path}")
    return ort.InferenceSession(path, providers=["CPUExecutionProvider"])

def get_session(tf: str) -> ort.InferenceSession:
    tf = (tf or "1m").lower().strip()
    if tf not in ("1m", "5m"):
        tf = "1m"
    if tf not in _sessions:
        _sessions[tf] = _load(tf)
    return _sessions[tf]

class PredictReq(BaseModel):
    tf: str = "1m"
    features: Optional[List[float]] = None
    shape: Optional[List[int]] = None
    input: Optional[List[float]] = None  # alias

@app.get("/health")
def health():
    return {"ok": True, "model_dir": MODEL_DIR}

@app.post("/predict")
def predict(req: PredictReq):
    sess = get_session(req.tf)

    feats = req.features if req.features is not None else req.input
    if feats is None:
        raise HTTPException(status_code=400, detail="Missing 'features' (or alias 'input')")

    arr = np.asarray(feats, dtype=np.float32)

    shp = req.shape
    if not shp:
        if arr.size == 300:
            shp = [1, 60, 5]
        else:
            if arr.size % 5 != 0:
                raise HTTPException(status_code=400, detail=f"Cannot infer shape from features length={arr.size}. Provide 'shape'.")
            shp = [1, arr.size // 5, 5]

    try:
        x = arr.reshape(shp)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Bad shape {shp} for features length={arr.size}: {e}")

    inp_name = sess.get_inputs()[0].name
    outs = sess.run(None, {inp_name: x})

    return {"output": np.asarray(outs[0]).tolist(), "tf": req.tf, "shape": shp}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)


