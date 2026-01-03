import time
import requests
from datetime import datetime, timezone
import MetaTrader5 as mt5

# ===== CONFIG =====
SERVER_HTTP  = "http://127.0.0.1:8080"
POST_TICK    = f"{SERVER_HTTP}/tick"
POST_OHLC    = f"{SERVER_HTTP}/candle"
POST_CANDLES = f"{SERVER_HTTP}/candles"
# POST_SIGNAL = f"{SERVER_HTTP}/signal"  # keep disabled for now (demo signals are confusing)

SYMBOLS = [
  "EURUSD_",
  "XAUUSD_",
  "BTCUSD",
  "ETHUSD",
]

TF_MAP = {
  "1m":  mt5.TIMEFRAME_M1,
  "5m":  mt5.TIMEFRAME_M5,
  "15m": mt5.TIMEFRAME_M15,
  "1h":  mt5.TIMEFRAME_H1,
}

HISTORY_LIMIT = 500   # >= 300 (startup)
CANDLES_LIMIT  = 500  # how many we read while running (we still post only last candle live)
TICK_SLEEP_SEC = 0.25
CANDLE_PUSH_EVERY_SEC = 3.0

def iso_now():
    return datetime.now(timezone.utc).isoformat()

def post_json(url, payload):
    try:
        r = requests.post(url, json=payload, timeout=8)
        return r.status_code, r.text
    except Exception as e:
        return 0, str(e)

def ensure_symbols(symbols):
    ok = []
    for s in symbols:
        if mt5.symbol_select(s, True):
            ok.append(s)
        else:
            print(f"[tawaqu3tickbridge] symbol_select failed for {s}")
    return ok

def get_tick(symbol):
    t = mt5.symbol_info_tick(symbol)
    if t is None:
        return None
    return {"symbol": symbol, "bid": float(t.bid), "ask": float(t.ask), "time": iso_now()}

def get_candles(symbol, tf_mt5, limit):
    rates = mt5.copy_rates_from_pos(symbol, tf_mt5, 0, limit)
    if rates is None or len(rates) == 0:
        return []
    out = []
    for r in rates:
        out.append({
            "time": datetime.fromtimestamp(int(r["time"]), tz=timezone.utc).isoformat(),
            "open": float(r["open"]),
            "high": float(r["high"]),
            "low":  float(r["low"]),
            "close":float(r["close"]),
            "volume": float(r["tick_volume"]),
        })
    return out

def push_history(ok_symbols):
    print(f"[tawaqu3tickbridge] pushing history: {HISTORY_LIMIT} candles لكل TF ...")
    for sym in ok_symbols:
        for tf_name, tf_mt5 in TF_MAP.items():
            candles = get_candles(sym, tf_mt5, HISTORY_LIMIT)
            if len(candles) < 1:
                print(f"[warn] no history for {sym} {tf_name}")
                continue

            code, txt = post_json(POST_CANDLES, {
                "symbol": sym,
                "tf": tf_name,
                "candles": candles,
            })
            if code != 200:
                print(f"[tawaqu3tickbridge] POST /candles failed {sym} {tf_name}: {code} {txt}")
            else:
                print(f"[ok] history -> {sym} {tf_name}: {len(candles)}")

    print("[tawaqu3tickbridge] history push done.")

def main():
    if not mt5.initialize():
        raise RuntimeError(f"MT5 init failed: {mt5.last_error()}")

    print("[tawaqu3tickbridge] MT5 connected.")
    ok_symbols = ensure_symbols(SYMBOLS)
    if not ok_symbols:
        raise RuntimeError("No valid symbols. Fix SYMBOLS to match Market Watch.")

    # Push history ONCE at startup (so the chart/model doesn't wait)
    push_history(ok_symbols)

    last_candle_push = 0.0

    while True:
        # ---- ticks
        for sym in ok_symbols:
            tick = get_tick(sym)
            if tick:
                post_json(POST_TICK, tick)

        # ---- live candle updates (last candle only)
        now = time.time()
        if now - last_candle_push >= CANDLE_PUSH_EVERY_SEC:
            last_candle_push = now
            for sym in ok_symbols:
                for tf_name, tf_mt5 in TF_MAP.items():
                    candles = get_candles(sym, tf_mt5, CANDLES_LIMIT)
                    if not candles:
                        continue
                    last = candles[-1]
                    post_json(POST_OHLC, {
                        "symbol": sym,
                        "tf": tf_name,
                        **last,
                    })

        time.sleep(TICK_SLEEP_SEC)

if __name__ == "__main__":
    main()
