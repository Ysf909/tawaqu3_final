from fastapi import FastAPI, Body
from fastapi.middleware.cors import CORSMiddleware
from typing import Any, Dict, List, Tuple, Optional
import os, numpy as np, requests
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
NODE_HTTP = os.getenv("NODE_HTTP", "http://127.0.0.1:8080")
DEFAULT_LOOKBACK = int(os.getenv("LOOKBACK", "60"))

_sessions: Dict[str, ort.InferenceSession] = {}

def _discover_models() -> Dict[str,str]:
    out: Dict[str,str] = {}
    if not os.path.isdir(MODEL_DIR):
        return out
    for fn in os.listdir(MODEL_DIR):
        if not fn.lower().endswith(".onnx"): continue
        p = os.path.join(MODEL_DIR, fn)
        f = fn.lower()
        if "1m" in f: out["1m"] = p
        elif "5m" in f: out["5m"] = p
        elif "15m" in f: out["15m"] = p
        elif "1h" in f: out["1h"] = p
        else: out.setdefault("default", p)
    if "default" not in out:
        for _,v in out.items():
            out["default"] = v; break
    return out

_MODELS = _discover_models()

def _get_session(tf: str) -> Tuple[ort.InferenceSession,str]:
    tf = (tf or "").lower()
    mp = _MODELS.get(tf) or _MODELS.get("default")
    if not mp:
        raise RuntimeError(f"No .onnx models found in {MODEL_DIR}")
    k = f"{tf}:{mp}"
    if k in _sessions: return _sessions[k], mp
    s = ort.InferenceSession(mp, providers=["CPUExecutionProvider"])
    _sessions[k] = s
    return s, mp

def _fetch_candles(symbol: str, tf: str, limit: int) -> List[Dict[str,Any]]:
    r = requests.get(f"{NODE_HTTP}/candles", params={"symbol":symbol,"tf":tf,"limit":limit}, timeout=8)
    r.raise_for_status()
    return (r.json().get("candles") or [])

def _candles_to_features(candles: List[Dict[str,Any]], n: int, f: int) -> List[List[float]]:
    candles = candles[-n:] if len(candles) > n else candles
    feats: List[List[float]] = []
    for c in candles:
        o = float(c.get("open", 0.0)); h=float(c.get("high",0.0)); l=float(c.get("low",0.0)); cl=float(c.get("close",0.0))
        v = float(c.get("volume", c.get("v", 0.0)) or 0.0)
        row = [o,h,l,cl,v]
        feats.append(row[:f])
    if len(feats) == 0:
        feats = [[0.0]*f for _ in range(n)]
    elif len(feats) < n:
        pad = [feats[0] for _ in range(n-len(feats))]
        feats = pad + feats
    return feats

def _prepare_input(sess: ort.InferenceSession, features: Any) -> Tuple[str,np.ndarray,Dict[str,Any]]:
    inp = sess.get_inputs()[0]
    name = inp.name
    shape = inp.shape
    s = [d if isinstance(d,int) else None for d in shape]

    arr = np.array(features, dtype=np.float32)
    dbg = {"input_name":name,"input_shape":shape,"features_ndim":int(arr.ndim),"features_shape":list(arr.shape)}

    if len(s) == 3:
        T = s[1] or (arr.shape[0] if arr.ndim >= 2 else DEFAULT_LOOKBACK)
        F = s[2] or (arr.shape[1] if arr.ndim >= 2 else 5)

        if arr.ndim == 1:
            flat = arr.flatten()
            need = T*F
            if flat.size < need: flat = np.pad(flat,(need-flat.size,0))
            else: flat = flat[-need:]
            arr = flat.reshape(T,F)

        if arr.ndim == 2:
            if arr.shape[1] != F:
                if arr.shape[1] > F: arr = arr[:,:F]
                else:
                    pad = np.zeros((arr.shape[0], F-arr.shape[1]), dtype=np.float32)
                    arr = np.concatenate([arr,pad], axis=1)
            if arr.shape[0] != T:
                if arr.shape[0] > T: arr = arr[-T:,:]
                else:
                    pad = np.repeat(arr[:1,:], T-arr.shape[0], axis=0)
                    arr = np.concatenate([pad,arr], axis=0)
            arr = arr.reshape(1,T,F)

    elif len(s) == 2:
        K = s[1] or arr.size
        flat = arr.flatten()
        if flat.size < K: flat = np.pad(flat,(K-flat.size,0))
        else: flat = flat[-K:]
        arr = flat.reshape(1,K)

    else:
        if arr.ndim == 0: arr = arr.reshape(1)

    dbg["final_input_shape"] = list(arr.shape)
    return name, arr, dbg

def _pick_side_and_score(outputs: List[np.ndarray]) -> Tuple[Optional[str], Optional[float]]:
    if not outputs: return None, None
    a = np.array(outputs[0]).astype(np.float32).flatten()
    if a.size == 0: return None, None
    if a.size == 1:
        v = float(a[0])
        return ("BUY" if v >= 0 else "SELL"), float(abs(v))
    idx = int(np.argmax(a))
    side = "BUY" if idx == 1 else "SELL"
    return side, float(a[idx])

@app.get("/health")
def health():
    return {"ok": True, "model_dir": MODEL_DIR, "node_http": NODE_HTTP, "models": _MODELS}

@app.post("/predict")
def predict(payload: Dict[str,Any] = Body(default_factory=dict)):
    symbol = str(payload.get("symbol") or "BTCUSD")
    tf = str(payload.get("tf") or "1m").lower()
    lookback = int(payload.get("lookback") or DEFAULT_LOOKBACK)

    features = payload.get("features") or payload.get("input")
    sess, model_path = _get_session(tf)

    if features is None:
        candles = payload.get("candles")
        if candles is None:
            candles = _fetch_candles(symbol, tf, lookback)
        inp = sess.get_inputs()[0]
        s = [d if isinstance(d,int) else None for d in inp.shape]
        F = (s[2] if len(s) == 3 else None) or 5
        features = _candles_to_features(candles, lookback, F)

    in_name, X, dbg = _prepare_input(sess, features)
    outs = sess.run(None, {in_name: X})

    # compatibility: return BOTH out (flat) and outputs (all tensors)
    outs_list = [np.array(o).tolist() for o in outs]
    out = (np.array(outs[0]).astype(np.float32).flatten().tolist() if outs else [])

    side, score = _pick_side_and_score([np.array(o) for o in outs])

    return {
        "ok": True,
        "symbol": symbol,
        "tf": tf,
        "lookback": lookback,
        "model": os.path.basename(model_path),
        "side": side,
        "score": score,
        "out": out,
        "outputs": outs_list,
        "debug": dbg,
    }
