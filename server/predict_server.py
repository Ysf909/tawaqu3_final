from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import os, json, math, urllib.request
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
ASSETS = os.path.abspath(os.path.join(HERE, "..", "assets", "models"))

ICT_DIR = os.path.join(ASSETS, "ict")
SMC_DIR = os.path.join(ASSETS, "smc")

def must(path: str):
    if not os.path.exists(path):
        raise RuntimeError(f"Missing model file: {path}")

ICT_1M = os.path.join(ICT_DIR, "ict_1m.onnx")
ICT_5M = os.path.join(ICT_DIR, "ict_5m.onnx")
SMC_15M = os.path.join(SMC_DIR, "smc_15m.onnx")
SMC_30M = os.path.join(SMC_DIR, "smc_30m.onnx")

for p in [ICT_1M, ICT_5M, SMC_15M, SMC_30M]:
    must(p)

SESS = {
    ("ict", "1m"): ort.InferenceSession(ICT_1M, providers=["CPUExecutionProvider"]),
    ("ict", "5m"): ort.InferenceSession(ICT_5M, providers=["CPUExecutionProvider"]),
    ("smc", "15m"): ort.InferenceSession(SMC_15M, providers=["CPUExecutionProvider"]),
    ("smc", "30m"): ort.InferenceSession(SMC_30M, providers=["CPUExecutionProvider"]),
}

def sigmoid(x: float) -> float:
    return 1.0 / (1.0 + math.exp(-x))

def softmax2(a: float, b: float):
    m = max(a, b)
    ea = math.exp(a - m)
    eb = math.exp(b - m)
    s = ea + eb
    if s == 0:
        return (0.5, 0.5)
    return (ea / s, eb / s)

def fetch_candles(symbol: str, tf: str, limit: int):
    url = f"http://127.0.0.1:8080/candles?symbol={symbol}&tf={tf}&limit={limit}"
    with urllib.request.urlopen(url, timeout=10) as r:
        data = json.loads(r.read().decode("utf-8"))
    candles = data.get("candles", data)
    if not isinstance(candles, list) or len(candles) == 0:
        raise RuntimeError("No candles returned from bridge.")
    return candles

def norm_candle(c):
    # supports both {open,high,low,close,volume} and {o,h,l,c,v}
    o = c.get("open", c.get("o", 0.0))
    h = c.get("high", c.get("h", 0.0))
    l = c.get("low",  c.get("l", 0.0))
    cl= c.get("close",c.get("c", 0.0))
    v = c.get("volume",c.get("v", 0.0))
    return float(o), float(h), float(l), float(cl), float(v)

def build_features_60(candles):
    last60 = candles[-60:] if len(candles) >= 60 else candles
    out = []
    for c in last60:
        o,h,l,cl,v = norm_candle(c)
        out += [o,h,l,cl,v]
    # pad to 300
    while len(out) < 300:
        out = [0.0,0.0,0.0,0.0,0.0] + out
    if len(out) > 300:
        out = out[-300:]
    return out

class PredictReq(BaseModel):
    model: Optional[str] = "ict"       # ict | smc
    tf: str                            # 1m/5m/15m/30m...
    shape: Optional[List[int]] = None  # [1,60,5]
    features: Optional[List[float]] = None

    # backward compatible:
    symbol: Optional[str] = None
    lookback: Optional[int] = 60

@app.post("/predict")
def predict(req: PredictReq):
    model = (req.model or "ict").lower().strip()
    tf = (req.tf or "").lower().strip()

    # route TF for ict
    if model == "ict":
        if tf == "1m":
            key = ("ict","1m")
        else:
            key = ("ict","5m")
    elif model == "smc":
        if tf not in ("15m","30m"):
            raise HTTPException(status_code=400, detail=f"SMC supports 15m/30m only, got {tf}")
        key = ("smc", tf)
    else:
        raise HTTPException(status_code=400, detail=f"Unknown model: {model}")

    sess = SESS.get(key)
    if sess is None:
        raise HTTPException(status_code=500, detail=f"Missing session for {key}")

    # features: prefer provided, else fetch candles from bridge
    feats = req.features
    if feats is None:
        if not req.symbol:
            raise HTTPException(status_code=400, detail="Missing features. Provide 'features' or 'symbol'.")
        candles = fetch_candles(req.symbol, tf, int(req.lookback or 60))
        feats = build_features_60(candles)

    if len(feats) != 300:
        raise HTTPException(status_code=400, detail=f"features must be 300 floats (60*5). Got {len(feats)}")

    x = np.array(feats, dtype=np.float32).reshape(1,60,5)

    inp = sess.get_inputs()[0].name
    out = sess.run(None, {inp: x})

    # flatten output
    vec = np.array(out[0]).reshape(-1).astype(np.float32).tolist()

    # interpret
    if len(vec) == 1:
        buy_prob = sigmoid(float(vec[0]))
    else:
        sell_p, buy_p = softmax2(float(vec[0]), float(vec[1]))
        buy_prob = buy_p

    side = "BUY" if buy_prob >= 0.5 else "SELL"
    score = float(buy_prob if side == "BUY" else (1.0 - buy_prob))

    return {"out": vec, "side": side, "score": score, "model": model, "tf": tf}
