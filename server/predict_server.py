from __future__ import annotations

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List, Dict, Any, Tuple
from pathlib import Path
import os
import math
import numpy as np
import requests
import onnxruntime as ort

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

HERE = Path(__file__).resolve().parent
PROJ = HERE.parent
ICT_DIR = (PROJ / "assets" / "models" / "ict").resolve()
SMC_DIR = (PROJ / "assets" / "models" / "smc").resolve()

CANDLES_BASE = os.getenv("CANDLES_BASE", "http://127.0.0.1:8080/candles")

def _softmax(x: np.ndarray) -> np.ndarray:
    x = x.astype(np.float64)
    x = x - np.max(x)
    e = np.exp(x)
    s = np.sum(e)
    return (e / s) if s != 0 else np.array([0.5, 0.5], dtype=np.float64)

def _sigmoid(x: float) -> float:
    return 1.0 / (1.0 + math.exp(-x))

def _load_session(path: Path) -> ort.InferenceSession:
    if not path.exists():
        raise FileNotFoundError(str(path))
    so = ort.SessionOptions()
    so.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
    return ort.InferenceSession(str(path), sess_options=so, providers=["CPUExecutionProvider"])

_SESS: Dict[str, ort.InferenceSession] = {}

def _get_sess(model_key: str) -> ort.InferenceSession:
    if model_key in _SESS:
        return _SESS[model_key]

    if model_key == "ict_1m":
        p = ICT_DIR / "ict_1m.onnx"
    elif model_key == "ict_5m":
        p = ICT_DIR / "ict_5m.onnx"
    elif model_key == "smc_15m":
        p = SMC_DIR / "smc_15m.onnx"
    elif model_key == "smc_30m":
        p = SMC_DIR / "smc_30m.onnx"
    else:
        raise KeyError(model_key)

    _SESS[model_key] = _load_session(p)
    return _SESS[model_key]

def _pick_model(tf: str) -> Tuple[str, str]:
    t = tf.lower().strip()
    if t == "1m":
        return ("ICT", "ict_1m")
    if t == "5m":
        return ("ICT", "ict_5m")
    if t == "15m":
        return ("SMC", "smc_15m")
    if t == "30m":
        return ("SMC", "smc_30m")
    # long/trend later (1h/4h/1d) - keep candles working even if model not added yet
    raise HTTPException(status_code=400, detail=f"Unsupported tf '{tf}'. Use 1m/5m (ICT) or 15m/30m (SMC).")

def _infer_expected_shape(sess: ort.InferenceSession, fallback_T: int, fallback_F: int) -> Tuple[int, int]:
    inp = sess.get_inputs()[0]
    shape = inp.shape  # usually [1, T, F]
    T = fallback_T
    F = fallback_F
    if len(shape) >= 3:
        if isinstance(shape[1], int):
            T = shape[1]
        if isinstance(shape[2], int):
            F = shape[2]
    return T, F

def _normalize_candle_row(c: Dict[str, Any]) -> Dict[str, float]:
    def g(*keys, default=0.0):
        for k in keys:
            if k in c and c[k] is not None:
                try:
                    return float(c[k])
                except Exception:
                    pass
        return float(default)

    return {
        "open": g("open","o"),
        "high": g("high","h"),
        "low":  g("low","l"),
        "close":g("close","c"),
        "volume": g("volume","v","tick_volume"),
        "spread": g("spread"),
        "real_volume": g("real_volume"),
    }

def _fetch_candles(symbol: str, tf: str, limit: int) -> List[Dict[str, Any]]:
    url = f"{CANDLES_BASE}?symbol={symbol}&tf={tf}&limit={limit}"
    r = requests.get(url, timeout=20)
    r.raise_for_status()
    j = r.json()
    candles = j.get("candles", j if isinstance(j, list) else [])
    if not isinstance(candles, list):
        candles = []
    return candles

def _build_X_from_candles(candles: List[Dict[str, Any]], T: int, F: int) -> np.ndarray:
    rows = []
    for c in candles:
        row = _normalize_candle_row(c)

        # ICT expects 5 features; SMC expects 7
        base = [row["open"], row["high"], row["low"], row["close"], row["volume"]]
        if F >= 7:
            base += [row["spread"], row["real_volume"]]
        # pad/truncate to F
        if len(base) < F:
            base += [0.0] * (F - len(base))
        base = base[:F]
        rows.append(base)

    arr = np.array(rows, dtype=np.float32)
    if arr.size == 0:
        arr = np.zeros((0, F), dtype=np.float32)

    # pad/trim time dimension
    if arr.shape[0] < T:
        if arr.shape[0] > 0:
            pad = np.repeat(arr[:1, :], T - arr.shape[0], axis=0)
        else:
            pad = np.zeros((T, F), dtype=np.float32)
        arr = np.vstack([pad, arr])
    if arr.shape[0] > T:
        arr = arr[-T:, :]

    return arr.reshape(1, T, F).astype(np.float32)

def _build_X_from_flat_features(features: List[float], T: int, F: int) -> np.ndarray:
    a = np.array(features, dtype=np.float32).reshape(-1)
    # try to reshape smartly
    if a.size == T * F:
        arr = a.reshape(T, F)
    else:
        # attempt infer T' from F first
        if F > 0 and (a.size % F == 0):
            t2 = a.size // F
            arr = a.reshape(t2, F)
        else:
            # fallback: assume rows, pad/truncate cols
            arr = a.reshape(-1, 1)

    # fix feature columns
    if arr.shape[1] < F:
        arr = np.hstack([arr, np.zeros((arr.shape[0], F - arr.shape[1]), dtype=np.float32)])
    if arr.shape[1] > F:
        arr = arr[:, :F]

    # fix time length
    if arr.shape[0] < T:
        pad = np.repeat(arr[:1, :], T - arr.shape[0], axis=0) if arr.shape[0] > 0 else np.zeros((T, F), dtype=np.float32)
        arr = np.vstack([pad, arr])
    if arr.shape[0] > T:
        arr = arr[-T:, :]

    return arr.reshape(1, T, F).astype(np.float32)

def _run(sess: ort.InferenceSession, X: np.ndarray) -> np.ndarray:
    inp_name = sess.get_inputs()[0].name
    outs = sess.run(None, {inp_name: X})
    y = np.array(outs[0])
    return y.reshape(-1).astype(np.float64)

def _to_side_conf(out: np.ndarray) -> Dict[str, Any]:
    # common cases:
    # - 2 logits: softmax
    # - 1 logit: sigmoid as BUY prob
    if out.size >= 2:
        probs = _softmax(out[:2])
        sell_p, buy_p = float(probs[0]), float(probs[1])
    else:
        buy_p = float(_sigmoid(float(out[0]))) if out.size == 1 else 0.5
        sell_p = 1.0 - buy_p

    side = "BUY" if buy_p >= sell_p else "SELL"
    conf = max(buy_p, sell_p) * 100.0
    return {"side": side, "confidence": conf, "buy_prob": buy_p, "sell_prob": sell_p}

class PredictReq(BaseModel):
    
    tf: str
    symbol: Optional[str] = None
    lookback: Optional[int] = 60
    features: Optional[List[float]] = None

@app.post("/predict")
def predict(req: PredictReq):
    school, model_key = _pick_model(req.tf)
    sess = _get_sess(model_key)

    # expected shape from model
    fallback_T = 60 if school == "ICT" else 256
    fallback_F = 5  if school == "ICT" else 7
    T, F = _infer_expected_shape(sess, fallback_T=fallback_T, fallback_F=fallback_F)

    if req.features is not None and len(req.features) > 0:
        X = _build_X_from_flat_features(req.features, T=T, F=F)
    else:
        if not req.symbol:
            raise HTTPException(status_code=422, detail="symbol is required when features are not provided")
        limit = req.lookback or T
        candles = _fetch_candles(req.symbol, req.tf, limit=limit)
        X = _build_X_from_candles(candles, T=T, F=F)

    out = _run(sess, X)
    meta = _to_side_conf(out)

    return {
        "school": school,
        "model": model_key,
        "symbol": req.symbol,
        "tf": req.tf,
        "expected_T": T,
        "expected_F": F,
        "side": meta["side"],
        "confidence": round(meta["confidence"], 2),
        "buy_prob": round(meta["buy_prob"], 6),
        "sell_prob": round(meta["sell_prob"], 6),
        "out": out.tolist(),
    }
