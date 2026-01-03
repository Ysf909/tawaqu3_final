import sys, os, re
import requests
import numpy as np
import onnxruntime as ort

NODE = "http://127.0.0.1:8080"
PRED = "http://127.0.0.1:8000/predict"

def model_path(tf: str) -> str:
    here = os.path.dirname(os.path.abspath(__file__))
    model_dir = os.path.abspath(os.path.join(here, "..", "assets", "models", "ict"))
    # adjust if your model file name is different
    # try common names
    for name in ["ict_tcn_best.onnx", f"ict_{tf}.onnx", "ict_1m.onnx", "ict_5m.onnx"]:
        p = os.path.join(model_dir, name)
        if os.path.exists(p):
            return p
    raise FileNotFoundError(f"No ONNX model found in {model_dir}")

def norm_dim(x):
    if x is None: return None
    if isinstance(x, (int, np.integer)): return int(x)
    if isinstance(x, str):
        m = re.search(r"\d+", x)
        return int(m.group()) if m else None
    return None

def get_input_shape(tf: str):
    p = model_path(tf)
    sess = ort.InferenceSession(p, providers=["CPUExecutionProvider"])
    inp = sess.get_inputs()[0]
    shp = [norm_dim(d) for d in (inp.shape or [])]
    return p, inp.name, shp

def fetch_candles(symbol: str, tf: str, limit: int):
    r = requests.get(f"{NODE}/candles", params={"symbol": symbol, "tf": tf, "limit": limit}, timeout=10)
    r.raise_for_status()
    j = r.json()
    if not j.get("ok"):
        raise RuntimeError(j)
    return j.get("candles", [])

def build_features_7(candles):
    # 7 features:
    # [open, high, low, close, volume, (high-low), (close-open)]
    X = []
    for c in candles:
        o = float(c["open"]); h = float(c["high"]); l = float(c["low"]); cl = float(c["close"])
        v = float(c.get("volume", 0.0))
        X.append([o, h, l, cl, v, (h - l), (cl - o)])
    return np.asarray(X, dtype=np.float32)

def main():
    symbol = (sys.argv[1] if len(sys.argv) > 1 else "BTCUSD").upper()
    tf = (sys.argv[2] if len(sys.argv) > 2 else "1m").lower()

    model_file, in_name, shp = get_input_shape(tf)
    print("model:", model_file)
    print("model input name:", in_name)
    print("model input shape:", shp)

    if len(shp) != 3 or shp[0] is None or shp[1] is None or shp[2] is None:
        raise RuntimeError("Model shape must be 3D fixed for this tester. Your model shape is dynamic; share it and I adapt.")

    B, D1, D2 = shp

    # Determine which dim is time (256) and which is features (7)
    # Expecting [77,256,7] (batch,time,features)
    if D1 == 256 and D2 == 7:
        T, F = 256, 7
        layout = "BTF"
    elif D1 == 7 and D2 == 256:
        T, F = 256, 7
        layout = "BFT"  # features,time
    else:
        # fallback: assume time is larger dim, features is smaller
        T = max(D1, D2)
        F = min(D1, D2)
        layout = "BTF" if D1 == T else "BFT"
        print(f"[warn] unexpected dims, guessing T={T}, F={F}, layout={layout}")

    # Always request >=300 candles on start, then use last 256 for model
    candles = fetch_candles(symbol, tf, 300)
    if len(candles) < T:
        raise RuntimeError(f"Not enough candles from Node: got {len(candles)} need {T}. Fix history push first.")

    candles = candles[-T:]
    X = build_features_7(candles)  # (T,7)

    if F != 7:
        raise RuntimeError(f"Model expects F={F}, but we are building 7 features. Tell me what the 7 features should be if different.")

    if layout == "BTF":
        one = X.reshape(1, T, F)
    else:
        one = X.T.reshape(1, F, T)

    # tile to fixed batch B (your model uses B=77)
    inp = np.repeat(one, repeats=B, axis=0).astype(np.float32)

    payload = {
        "tf": tf,
        "shape": list(inp.shape),
        "features": inp.reshape(-1).tolist(),
        "input": inp.reshape(-1).tolist(),
    }

    r = requests.post(PRED, json=payload, timeout=30)
    print("status:", r.status_code)
    print(r.text)

if __name__ == "__main__":
    main()
