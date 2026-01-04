import time
import requests
from datetime import datetime, timezone, timedelta
import MetaTrader5 as mt5

SERVER_HTTP  = "http://127.0.0.1:8080"
POST_TICK    = f"{SERVER_HTTP}/tick"
POST_OHLC    = f"{SERVER_HTTP}/candle"
POST_CANDLES = f"{SERVER_HTTP}/candles"

# What you want in the app (normalized names without underscore)
BASE_ASSETS = ["BTCUSD","ETHUSD","XAUUSD","XAGUSD","EURUSD"]

TF_MAP = {
  "1m":  mt5.TIMEFRAME_M1,
  "5m":  mt5.TIMEFRAME_M5,
  "15m": mt5.TIMEFRAME_M15,
  "30m": mt5.TIMEFRAME_M30,
  "1h":  mt5.TIMEFRAME_H1,
  "4h":  mt5.TIMEFRAME_H4,
  "1d":  mt5.TIMEFRAME_D1,
}

# Try to pull enough bars for ~800 candles
WARMUP_DAYS = {
  "1m": 7,
  "5m": 30,
  "15m": 90,
  "30m": 180,
  "1h": 365,
  "4h": 3*365,
  "1d": 5*365,
}

HISTORY_LIMIT = 800     # send bulk history on startup
LIVE_FETCH    = 3       # live mode: fetch few bars, post last candle only
TICK_SLEEP_SEC = 0.25
CANDLE_PUSH_EVERY_SEC = 3.0

def now_utc():
    return datetime.now(timezone.utc)

def iso_now():
    return now_utc().isoformat().replace("+00:00","Z")

def iso_from_epoch(ts: int):
    return datetime.fromtimestamp(int(ts), tz=timezone.utc).isoformat().replace("+00:00","Z")

def norm_symbol(s: str) -> str:
    s = (s or "").strip()
    return s[:-1] if s.endswith("_") else s

def post_json(url, payload):
    try:
        r = requests.post(url, json=payload, timeout=8)
        return r.status_code, r.text
    except Exception as e:
        return 0, str(e)

def pick_mt5_symbol(base: str) -> str | None:
    # Try base, base_ (common brokers)
    for cand in (base, base + "_"):
        info = mt5.symbol_info(cand)
        if info is not None:
            if mt5.symbol_select(cand, True):
                return cand
    return None

def get_tick(mt5_symbol: str):
    t = mt5.symbol_info_tick(mt5_symbol)
    if t is None:
        return None
    return {"bid": float(t.bid), "ask": float(t.ask), "time": iso_now()}

def warmup_history(mt5_symbol: str, tf_mt5, tf_name: str):
    # Force MT5 to download data by requesting a date range
    end = now_utc()
    start = end - timedelta(days=WARMUP_DAYS.get(tf_name, 30))
    _ = mt5.copy_rates_range(mt5_symbol, tf_mt5, start, end)

def get_candles_from_pos(mt5_symbol: str, tf_mt5, limit: int):
    rates = mt5.copy_rates_from_pos(mt5_symbol, tf_mt5, 0, limit)
    if rates is None or len(rates) == 0:
        return []
    out = []
    for r in rates:
        out.append({
            "time": iso_from_epoch(r["time"]),
            "open": float(r["open"]),
            "high": float(r["high"]),
            "low":  float(r["low"]),
            "close":float(r["close"]),
            "volume": float(r["tick_volume"]) if "tick_volume" in r.dtype.names else (float(r["real_volume"]) if "real_volume" in r.dtype.names else 0.0),
        })
    out.sort(key=lambda x: x["time"])
    return out

def get_candles_retry(mt5_symbol: str, tf_mt5, tf_name: str, limit: int, retries=8, delay=0.8):
    best = []
    for i in range(retries):
        warmup_history(mt5_symbol, tf_mt5, tf_name)
        candles = get_candles_from_pos(mt5_symbol, tf_mt5, limit)
        if len(candles) > len(best):
            best = candles
        if len(best) >= min(limit, 60):  # enough for ICT or full target
            break
        time.sleep(delay)
    return best

def push_history(symbol_map: dict):
    print(f"[bridge] pushing history for all assets/timeframes (target {HISTORY_LIMIT}) ...")
    for app_sym, mt5_sym in symbol_map.items():
        for tf_name, tf_mt5 in TF_MAP.items():
            candles = get_candles_retry(mt5_sym, tf_mt5, tf_name, HISTORY_LIMIT)
            if not candles:
                print(f"[warn] no history for {app_sym} {tf_name}")
                continue

            code, txt = post_json(POST_CANDLES, {
                "symbol": app_sym,   # normalized
                "tf": tf_name,
                "candles": candles
            })
            if code != 200:
                print(f"[err] POST /candles failed {app_sym} {tf_name}: {code} {txt}")
            else:
                print(f"[ok] history -> {app_sym} {tf_name}: {len(candles)}")

    print("[bridge] history push done.")

def main():
    if not mt5.initialize():
        raise RuntimeError(f"MT5 init failed: {mt5.last_error()}")

    # Build symbol map: app symbol -> mt5 symbol (handles underscore brokers)
    symbol_map = {}
    for base in BASE_ASSETS:
        mt5_sym = pick_mt5_symbol(base)
        if mt5_sym:
            symbol_map[base] = mt5_sym
        else:
            print(f"[warn] symbol not found in MT5: {base} / {base}_")

    if not symbol_map:
        raise RuntimeError("No valid symbols selected. Add them to Market Watch and retry.")

    print("[bridge] MT5 connected. Using:")
    for k,v in symbol_map.items():
        print(f"  {k} <= {v}")

    # Bulk history on startup
    push_history(symbol_map)

    last_candle_push = 0.0
    while True:
        # ticks (best effort; forex/metals may be closed)
        for app_sym, mt5_sym in symbol_map.items():
            tk = get_tick(mt5_sym)
            if tk:
                post_json(POST_TICK, {"symbol": app_sym, **tk})

        # last-candle update
        now = time.time()
        if now - last_candle_push >= CANDLE_PUSH_EVERY_SEC:
            last_candle_push = now
            for app_sym, mt5_sym in symbol_map.items():
                for tf_name, tf_mt5 in TF_MAP.items():
                    candles = get_candles_from_pos(mt5_sym, tf_mt5, LIVE_FETCH)
                    if not candles:
                        continue
                    last = candles[-1]
                    post_json(POST_OHLC, {"symbol": app_sym, "tf": tf_name, **last})

        time.sleep(TICK_SLEEP_SEC)

if __name__ == "__main__":
    main()

