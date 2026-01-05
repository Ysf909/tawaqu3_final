import time
import re
import requests
from datetime import datetime, timezone

import MetaTrader5 as mt5

SERVER_HTTP = "http://127.0.0.1:8080"
POST_TICK   = f"{SERVER_HTTP}/tick"
POST_OHLC   = f"{SERVER_HTTP}/candle"

# Put EXACT broker symbols here (Market Watch). We will "clean" suffixes before posting to Node.
SYMBOLS = [
  "XAUUSD_",
  "XAGUSD_",
  "BTCUSD",
  "ETHUSD",
  "EURUSD_",
]

TF_MAP = {
  "1m":  mt5.TIMEFRAME_M1,
  "5m":  mt5.TIMEFRAME_M5,
  "15m": mt5.TIMEFRAME_M15,
  "30m": mt5.TIMEFRAME_M30,
  "1h":  mt5.TIMEFRAME_H1,
  "4h":  mt5.TIMEFRAME_H4,
  "1d":  mt5.TIMEFRAME_D1,
}

BACKFILL_LIMIT = 800          # <-- initial history count per tf per symbol
BACKFILL_SLEEP = 0.01         # small delay so we don't overload Node
TICK_SLEEP_SEC = 0.25
CANDLE_PUSH_EVERY_SEC = 2.0

def iso_from_epoch_sec(t:int) -> str:
  return datetime.fromtimestamp(int(t), tz=timezone.utc).isoformat()

def clean_symbol(s: str) -> str:
  # remove trailing non-alphanumeric like "_" or "#"
  return re.sub(r"[^A-Za-z0-9]+$", "", s)

def post_json(url, payload):
  try:
    r = requests.post(url, json=payload, timeout=3)
    return r.status_code, r.text
  except Exception as e:
    return 0, str(e)

def ensure_symbols(symbols):
  ok = []
  for s in symbols:
    if mt5.symbol_select(s, True):
      ok.append(s)
    else:
      print(f"[bridge] symbol_select failed for {s}")
  return ok

def get_tick(symbol):
  t = mt5.symbol_info_tick(symbol)
  if t is None: return None
  return {"symbol": clean_symbol(symbol), "bid": float(t.bid), "ask": float(t.ask), "time": datetime.now(timezone.utc).isoformat()}

def copy_rates(symbol, tf_mt5, limit):
  rates = mt5.copy_rates_from_pos(symbol, tf_mt5, 0, int(limit))
  if rates is None or len(rates) == 0:
    return []
  return rates

def backfill_symbol_tf(symbol, tf_name, tf_mt5, limit):
  rates = copy_rates(symbol, tf_mt5, limit)
  if rates is None or len(rates)==0:
    print(f"[backfill] no rates: {symbol} {tf_name}")
    return

  sym_clean = clean_symbol(symbol)
  # post oldest -> newest
  for r in rates:
    post_json(POST_OHLC, {
      "symbol": sym_clean,
      "tf": tf_name,
      "time": iso_from_epoch_sec(r["time"]),
      "open": float(r["open"]),
      "high": float(r["high"]),
      "low": float(r["low"]),
      "close": float(r["close"]),
      "volume": float(r["tick_volume"]),
    })
    time.sleep(BACKFILL_SLEEP)

  print(f"[backfill] done {sym_clean} {tf_name}: {len(rates)} bars")

def main():
  if not mt5.initialize():
    raise RuntimeError(f"MT5 init failed: {mt5.last_error()}")

  print("[bridge] MT5 connected.")
  ok_symbols = ensure_symbols(SYMBOLS)
  if not ok_symbols:
    raise RuntimeError("No valid symbols. Fix SYMBOLS to match Market Watch.")

  print("[bridge] symbols:", [clean_symbol(s) for s in ok_symbols])
  print("[bridge] timeframes:", list(TF_MAP.keys()))

  # one-time backfill
  for sym in ok_symbols:
    for tf_name, tf_mt5 in TF_MAP.items():
      backfill_symbol_tf(sym, tf_name, tf_mt5, BACKFILL_LIMIT)

  last_push = 0.0
  while True:
    for sym in ok_symbols:
      tick = get_tick(sym)
      if tick:
        post_json(POST_TICK, tick)

    now = time.time()
    if now - last_push >= CANDLE_PUSH_EVERY_SEC:
      last_push = now
      for sym in ok_symbols:
        sym_clean = clean_symbol(sym)
        for tf_name, tf_mt5 in TF_MAP.items():
          rates = copy_rates(sym, tf_mt5, 3)
          if rates is None or len(rates) == 0:

            continue
          last_closed = rates[-2]
          post_json(POST_OHLC, {
            "symbol": sym_clean,
            "tf": tf_name,
            "time": iso_from_epoch_sec(last_closed["time"]),
            "open": float(last_closed["open"]),
            "high": float(last_closed["high"]),
            "low": float(last_closed["low"]),
            "close": float(last_closed["close"]),
            "volume": float(last_closed["tick_volume"]),
          })

    time.sleep(TICK_SLEEP_SEC)

if __name__ == "__main__":
  main()



# --- TF_PATCH ---
# Ensure full TF set (ICT+SMC+TREND) + keep 800 backfill
try:
    TIMEFRAMES
except NameError:
    TIMEFRAMES = {}

try:
    import MetaTrader5 as mt5
    TIMEFRAMES.update({
        "1m": mt5.TIMEFRAME_M1,
        "5m": mt5.TIMEFRAME_M5,
        "15m": mt5.TIMEFRAME_M15,
        "30m": mt5.TIMEFRAME_M30,
        "1h": mt5.TIMEFRAME_H1,
        "4h": mt5.TIMEFRAME_H4,
        "1d": mt5.TIMEFRAME_D1,
    })
except Exception:
    pass

try:
    BACKFILL_LIMIT = max(int(BACKFILL_LIMIT), 800)
except Exception:
    BACKFILL_LIMIT = 800
# --- TF_PATCH ---

