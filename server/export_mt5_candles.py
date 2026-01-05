import argparse, os
import pandas as pd
from datetime import datetime, timezone
import MetaTrader5 as mt5

TF_MAP = {
  "1m": mt5.TIMEFRAME_M1,
  "5m": mt5.TIMEFRAME_M5,
  "15m": mt5.TIMEFRAME_M15,
  "30m": mt5.TIMEFRAME_M30,
  "1h": mt5.TIMEFRAME_H1,
  "4h": mt5.TIMEFRAME_H4,
  "1d": mt5.TIMEFRAME_D1,
}

def die(msg):
  raise SystemExit(msg)

def main():
  ap = argparse.ArgumentParser()
  ap.add_argument("--symbol", required=True)
  ap.add_argument("--tf", required=True)
  ap.add_argument("--count", type=int, required=True)
  ap.add_argument("--out", required=True)
  ap.add_argument("--chunk", type=int, default=5000)
  args = ap.parse_args()

  tf = args.tf.lower()
  if tf not in TF_MAP:
    die(f"Unsupported tf={args.tf}. Allowed: {list(TF_MAP.keys())}")

  if not mt5.initialize():
    die(f"MT5 initialize() failed: {mt5.last_error()}\n"
        f"Open MetaTrader 5 terminal, login to broker, then run again.")

  symbol = args.symbol.upper()
  if not mt5.symbol_select(symbol, True):
    die(f"symbol_select failed for {symbol}: {mt5.last_error()}")

  total = args.count
  chunk = max(100, args.chunk)
  offset = 0
  rows = []

  while len(rows) < total:
    need = min(chunk, total - len(rows))
    rates = mt5.copy_rates_from_pos(symbol, TF_MAP[tf], offset, need)

    # if history not loaded enough, you get None/empty
    if rates is None or len(rates) == 0:
      break

    rows.append(rates)
    offset += len(rates)

    # safety stop if MT5 stops giving older data
    if len(rates) < need:
      break

  mt5.shutdown()

  if not rows:
    die(
      f"No rates returned for {symbol} {tf}.\n"
      f"Fix: In MT5 -> Tools->Options->Charts set 'Max bars in history' and 'Max bars in chart' to a big number,\n"
      f"then open {symbol} chart on {tf} and press Home to load more history."
    )

  import numpy as np
  arr = np.concatenate(rows, axis=0)

  df = pd.DataFrame(arr)
  # df columns: time, open, high, low, close, tick_volume, spread, real_volume
  df["time"] = df["time"].apply(lambda s: datetime.fromtimestamp(int(s), tz=timezone.utc).isoformat())
  df.rename(columns={"tick_volume":"volume"}, inplace=True)

  df.insert(0, "tf", tf)
  df.insert(0, "symbol", symbol)

  df = df[["symbol","tf","time","open","high","low","close","volume"]]

  # MT5 returns from newest->older with offset paging; reverse to chronological
  df = df.iloc[::-1].reset_index(drop=True)

  os.makedirs(args.out, exist_ok=True)
  out_file = os.path.join(args.out, f"{symbol}_{tf}_mt5_{len(df)}.csv")
  df.to_csv(out_file, index=False, encoding="utf-8")
  print(f"OK {symbol} {tf}: saved {len(df)} -> {out_file}")

if __name__ == "__main__":
  main()
