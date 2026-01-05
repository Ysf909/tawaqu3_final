import os, glob, argparse, math, random
import numpy as np
import pandas as pd

# ---- torch ----
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader

# -------------------------
# Utils
# -------------------------
def set_seed(seed: int):
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)

def compute_atr(high, low, close, period=14):
    high = np.asarray(high, dtype=np.float64)
    low  = np.asarray(low, dtype=np.float64)
    close= np.asarray(close, dtype=np.float64)
    prev_close = np.concatenate([[close[0]], close[:-1]])
    tr = np.maximum(high - low, np.maximum(np.abs(high - prev_close), np.abs(low - prev_close)))
    atr = np.full_like(tr, np.nan, dtype=np.float64)
    for i in range(period - 1, len(tr)):
        atr[i] = np.mean(tr[i - (period - 1): i + 1])
    return atr

def build_feature_window(win_ohlcv: np.ndarray) -> np.ndarray:
    """
    win_ohlcv: shape (60, 5) = [open,high,low,close,volume]
    returns:   shape (60, 5) float32 normalized
    """
    w = win_ohlcv.astype(np.float64)

    # normalize price columns relative to last close (stationary across price levels)
    ref = w[-1, 3]
    if ref == 0 or not np.isfinite(ref):
        ref = np.nanmean(w[:, 3])
        if not np.isfinite(ref) or ref == 0:
            ref = 1.0
    w[:, 0:4] = (w[:, 0:4] / ref) - 1.0

    # normalize volume (z-score on log1p)
    v = np.log1p(np.maximum(w[:, 4], 0.0))
    v = (v - v.mean()) / (v.std() + 1e-6)
    w[:, 4] = v

    return w.astype(np.float32)

def simulate_label(df: pd.DataFrame, lookback=60, horizon=24, atr_period=14):
    """
    Label = 1 (BUY) or 0 (SELL)
    Only keep samples where:
      BUY -> TP before SL AND SELL -> SL before TP  => BUY label
      SELL-> TP before SL AND BUY  -> SL before TP  => SELL label
    Ambiguous cases are skipped.
    """
    d = df.copy()
    d["t"] = pd.to_datetime(d["time"], utc=True)
    d.sort_values("t", inplace=True)

    o = d["open"].to_numpy(np.float64)
    h = d["high"].to_numpy(np.float64)
    l = d["low"].to_numpy(np.float64)
    c = d["close"].to_numpy(np.float64)
    v = d["volume"].to_numpy(np.float64)

    atr = compute_atr(h, l, c, period=atr_period)

    X, y, ts = [], [], []

    n = len(d)
    for i in range(lookback, n - horizon - 1):
        if not np.isfinite(atr[i]):
            continue

        entry = c[i]
        slDist = max(atr[i] * 1.5, abs(entry) * 0.0008)
        tpDist = slDist * 2.0

        buy_tp  = entry + tpDist
        buy_sl  = entry - slDist
        sell_tp = entry - tpDist
        sell_sl = entry + slDist

        def path_result(is_buy: bool):
            # returns 'TP', 'SL', or None/ambiguous
            for j in range(i + 1, i + 1 + horizon):
                if is_buy:
                    hit_tp = h[j] >= buy_tp
                    hit_sl = l[j] <= buy_sl
                else:
                    hit_tp = l[j] <= sell_tp
                    hit_sl = h[j] >= sell_sl

                if hit_tp and hit_sl:
                    return None  # ambiguous intrabar -> skip
                if hit_tp:
                    return "TP"
                if hit_sl:
                    return "SL"
            return None

        buy_res  = path_result(True)
        sell_res = path_result(False)

        if buy_res is None or sell_res is None:
            continue

        if buy_res == "TP" and sell_res == "SL":
            label = 1
        elif sell_res == "TP" and buy_res == "SL":
            label = 0
        else:
            continue

        win = np.stack([o[i - lookback:i], h[i - lookback:i], l[i - lookback:i], c[i - lookback:i], v[i - lookback:i]], axis=1)
        feat = build_feature_window(win)

        X.append(feat)
        y.append(label)
        ts.append(d["t"].iloc[i].to_datetime64())

    return np.array(X, dtype=np.float32), np.array(y, dtype=np.int64), np.array(ts)

# -------------------------
# Model (simple 1D CNN)
# -------------------------
class CandleCNN(nn.Module):
    def __init__(self, in_ch=5):
        super().__init__()
        self.net = nn.Sequential(
            nn.Conv1d(in_ch, 32, kernel_size=3, padding=1),
            nn.ReLU(),
            nn.Conv1d(32, 64, kernel_size=3, padding=1),
            nn.ReLU(),
            nn.AdaptiveAvgPool1d(1),
        )
        self.fc = nn.Linear(64, 1)  # logits for BUY

    def forward(self, x):
        # x: [B, 60, 5] -> [B, 5, 60]
        x = x.permute(0, 2, 1)
        z = self.net(x).squeeze(-1)
        return self.fc(z).squeeze(-1)  # [B]

class NpDataset(Dataset):
    def __init__(self, X, y):
        self.X = torch.from_numpy(X)
        self.y = torch.from_numpy(y).float()

    def __len__(self):
        return self.X.shape[0]

    def __getitem__(self, idx):
        return self.X[idx], self.y[idx]

def train_one(tf_name, X, y, ts, out_dir, epochs=25, batch=128, lr=1e-3, seed=7):
    # time split (no leakage)
    order = np.argsort(ts)
    X, y = X[order], y[order]

    n = len(X)
    if n < 200:
        raise RuntimeError(f"Not enough samples for {tf_name}. Got {n}.")

    n_train = int(n * 0.8)
    n_val   = n - n_train

    Xtr, ytr = X[:n_train], y[:n_train]
    Xva, yva = X[n_train:], y[n_train:]

    model = CandleCNN(in_ch=5)
    opt = torch.optim.Adam(model.parameters(), lr=lr)
    loss_fn = nn.BCEWithLogitsLoss()

    dl_tr = DataLoader(NpDataset(Xtr, ytr), batch_size=batch, shuffle=True, drop_last=False)
    dl_va = DataLoader(NpDataset(Xva, yva), batch_size=batch, shuffle=False, drop_last=False)

    best_val = 1e9
    best_path = os.path.join(out_dir, f"smc_{tf_name}.pt")

    for ep in range(1, epochs + 1):
        model.train()
        tr_losses = []
        for xb, yb in dl_tr:
            opt.zero_grad()
            logits = model(xb)
            loss = loss_fn(logits, yb)
            loss.backward()
            opt.step()
            tr_losses.append(loss.item())

        model.eval()
        va_losses = []
        correct = 0
        total = 0
        with torch.no_grad():
            for xb, yb in dl_va:
                logits = model(xb)
                loss = loss_fn(logits, yb)
                va_losses.append(loss.item())
                prob = torch.sigmoid(logits)
                pred = (prob >= 0.5).float()
                correct += (pred == yb).sum().item()
                total += yb.numel()

        tr_loss = float(np.mean(tr_losses))
        va_loss = float(np.mean(va_losses))
        acc = 100.0 * correct / max(total, 1)

        print(f"[{tf_name}] ep {ep:02d} | train {tr_loss:.4f} | val {va_loss:.4f} | val_acc {acc:.1f}%")

        if va_loss < best_val:
            best_val = va_loss
            torch.save(model.state_dict(), best_path)

    # load best and export ONNX
    model.load_state_dict(torch.load(best_path, map_location="cpu"))
    model.eval()

    onnx_path = os.path.join(out_dir, f"smc_{tf_name}.onnx")
    dummy = torch.randn(1, 60, 5, dtype=torch.float32)

    torch.onnx.export(
        model,
        dummy,
        onnx_path,
        input_names=["x"],
        output_names=["logits"],
        opset_version=18,
        do_constant_folding=True,
        dynamo=False,
    )

    print(f"âœ… Saved ONNX: {onnx_path}")
    return onnx_path

def load_csvs(data_dir):
    files = glob.glob(os.path.join(data_dir, "*.csv"))
    if not files:
        raise RuntimeError(f"No CSV found in {data_dir}")
    dfs = []
    for f in files:
        df = pd.read_csv(f)
        need = {"time","open","high","low","close","volume","symbol","tf"}
        if not need.issubset(set(df.columns)):
            raise RuntimeError(f"{os.path.basename(f)} missing columns. Found: {list(df.columns)}")
        dfs.append(df)
    return pd.concat(dfs, ignore_index=True)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data-dir", required=True, help="folder containing CSV files")
    ap.add_argument("--out-dir", required=True, help="output folder for ONNX")
    ap.add_argument("--epochs", type=int, default=25)
    ap.add_argument("--batch", type=int, default=128)
    ap.add_argument("--lr", type=float, default=1e-3)
    ap.add_argument("--lookback", type=int, default=60)
    ap.add_argument("--horizon", type=int, default=24)
    ap.add_argument("--seed", type=int, default=7)
    args = ap.parse_args()

    set_seed(args.seed)
    os.makedirs(args.out_dir, exist_ok=True)

    all_df = load_csvs(args.data_dir)

    # Train per TF (15m and 30m)
    for tf_name in ["15m", "30m"]:
        df_tf = all_df[all_df["tf"].astype(str).str.lower() == tf_name]
        if df_tf.empty:
            print(f"Skip {tf_name}: no data")
            continue

        # combine symbols but keep ordering per symbol (we label per symbol)
        Xs, ys, tss = [], [], []
        for sym in sorted(df_tf["symbol"].unique()):
            df_sym = df_tf[df_tf["symbol"] == sym]
            X, y, ts = simulate_label(df_sym, lookback=args.lookback, horizon=args.horizon)
            print(f"{tf_name} {sym}: samples={len(X)}")
            if len(X) > 0:
                Xs.append(X); ys.append(y); tss.append(ts)

        if not Xs:
            raise RuntimeError(f"No training samples built for {tf_name}")

        X = np.concatenate(Xs, axis=0)
        y = np.concatenate(ys, axis=0)
        ts = np.concatenate(tss, axis=0)

        print(f"\nTF {tf_name}: total samples={len(X)} | BUY%={100.0*y.mean():.1f}%\n")
        train_one(tf_name, X, y, ts, out_dir=args.out_dir, epochs=args.epochs, batch=args.batch, lr=args.lr, seed=args.seed)

if __name__ == "__main__":
    main()

