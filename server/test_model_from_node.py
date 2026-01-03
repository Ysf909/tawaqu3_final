import sys, os, json
import requests
import numpy as np
import onnxruntime as ort

NODE = "http://127.0.0.1:8080"
PRED = "http://127.0.0.1:8000/predict"

def model_path(tf: str) -> str:
    here = os.path.dirname(os.path.abspath(__file__))
    model_dir = os.path.abspath(os.path.join(here, "..", "assets", "models", "ict"))
    return os.path.join(model_dir, "ict_1m.onnx" if tf == "1m" else "ict_5m.onnx")

def get_model_input_shape(tf: str):
    p = model_path(tf)
    sess = ort.InferenceSession(p, providers=["CPUExecutionProvider"])
    shp = sess.get_inputs()[0].shape  # e.g. [1,60,5] or [1,5,60] or [None,60,4]
    return [None if x is None else int(x) for x in shp]

def fetch_candles(symbol: str, tf: str, limit: int):
    r = requests.get(f"{NODE}/candles", params={"symbol": symbol, "tf": tf, "limit": limit}, timeout=8)
    r.raise_for_status()
    j = r.json()
    if not j.get("ok"):
        raise RuntimeError(j)
    return j.get("candles", [])

def build_X(candles, F: int):
    X = []
    for c in candles:
        row = [
            float(c["open"]),
            float(c["high"]),
            float(c["low"]),
            float(c["close"]),
        ]
        if F >= 5:
            row.append(float(c.get("volume", 0.0)))
        while len(row) < F:
            row.append(0.0)
        X.append(row[:F])
    return np.asarray(X, dtype=np.float32)

def main():
    symbol = (sys.argv[1] if len(sys.argv) > 1 else "BTCUSD").upper()
    tf = (sys.argv[2] if len(sys.argv) > 2 else "1m").lower()

    shp = get_model_input_shape(tf)
    # We will support both [1,T,F] and [1,F,T]
    # Heuristic: feature dim is usually small (<=10)
    if len(shp) == 3:
        _, d1, d2 = shp
        d1v = d1 if d1 is not None else -1
        d2v = d2 if d2 is not None else -1

        if 0 < d1v <= 10:
            F = d1v
            T = d2v if d2v > 0 else 60
            layout = "1FT"  # [1,F,T]
            target_shape = [1, F, T]
        else:
            F = d2v if d2v > 0 else 5
            T = d1v if d1v > 0 else 60
            layout = "1TF"  # [1,T,F]
            target_shape = [1, T, F]
    else:
        # fallback
        T, F = 60, 5
        layout = "1TF"
        target_shape = [1, T, F]

    candles = fetch_candles(symbol, tf, T)
    if len(candles) < T:
        print(f"[warn] got only {len(candles)} candles (expected {T}). Using available.")
        T = len(candles)
        if layout == "1FT":
            target_shape = [1, F, T]
        else:
            target_shape = [1, T, F]

    X = build_X(candles, F)
    if layout == "1FT":
        X = X.T  # (F,T)

    feats = X.reshape(-1).tolist()

    payload = {"tf": tf, "shape": target_shape, "features": feats}
    r = requests.post(PRED, json=payload, timeout=20)

    print("status:", r.status_code)
    print(r.text)

    if r.ok:
        out = r.json().get("output")
        arr = np.asarray(out)
        print("output numpy shape:", arr.shape)
        flat = arr.reshape(-1)
        print("output head:", flat[:10].tolist())
        # if it looks like class probs/logits (e.g. last dim = 2 or 3), print argmax
        if flat.size in (2,3) or (arr.ndim >= 2 and arr.shape[-1] in (2,3)):
            try:
                pred = int(np.argmax(arr.reshape(-1)))
                print("argmax class index:", pred)
            except Exception:
                pass

if __name__ == "__main__":
    main()
