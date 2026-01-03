import time
import requests
from datetime import datetime, timezone

import MetaTrader5 as mt5

# ===== CONFIG =====
SERVER_HTTP = "http://127.0.0.1:8080"
POST_TICK    = f"{SERVER_HTTP}/tick"
POST_OHLC    = f"{SERVER_HTTP}/candle"
POST_CANDLES = f"{SERVER_HTTP}/candles"
POST_SIGNAL  = f"{SERVER_HTTP}/signal"

# Put EXACT broker names here (Market Watch)
SYMBOLS = [
  "EURUSD_",
  "XAUUSD_",
  "BTCUSD",
  "ETHUSD",
]

TF_MAP = {
    "1m": mt5.TIMEFRAME_M1,
    "5m": mt5.TIMEFRAME_M5,
}

# How many bars to push as history on start
HISTORY_LIMIT = 400

# Still used for live fetch
CANDLES_LIMIT = 120

TICK_SLEEP_SEC = 0.25
CANDLE_PUSH_EVERY_SEC = 1.0   # faster, but safe since we will dedupe

def iso_now():
    return datetime.now(timezone.utc).isoformat()

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
            print(f"[tawaqu3tickbridge] symbol_select failed for {s}")
    return ok

def get_tick(symbol):
    t = mt5.symbol_info_tick(symbol)
    if t is None:
        return None
    return {"symbol": symbol, "bid": float(t.bid), "ask": float(t.ask), "time": iso_now()}

def get_candles(symbol, tf_mt5, limit):
    rates = mt5.copy_rates_from_pos(symbol, tf_mt5, 0, limit)
    if rates is None:
        return []
    out = []
    for r in rates:
        out.append({
            "t": int(r["time"]) * 1000,  # ms
            "o": float(r["open"]),
            "h": float(r["high"]),
            "l": float(r["low"]),
            "c": float(r["close"]),
            "v": float(r["tick_volume"]),
        })
    return out

def push_history(ok_symbols):
    print("[tawaqu3tickbridge] pushing history candles...")
    for sym in ok_symbols:
        for tf_name, tf_mt5 in TF_MAP.items():
            candles = get_candles(sym, tf_mt5, HISTORY_LIMIT)
            if not candles:
                continue

            payload = {
                "symbol": sym,
                "tf": tf_name,
                "candles": [
                    {
                        "time": datetime.fromtimestamp(c["t"]/1000, tz=timezone.utc).isoformat(),
                        "open": c["o"],
                        "high": c["h"],
                        "low":  c["l"],
                        "close": c["c"],
                        "volume": c.get("v", 0.0),
                    }
                    for c in candles
                ],
            }

            code, txt = post_json(POST_CANDLES, payload)
            if code != 200:
                print(f"[tawaqu3tickbridge] POST /candles failed {sym} {tf_name}: {code} {txt}")

    print("[tawaqu3tickbridge] history done.")

def main():
    if not mt5.initialize():
        raise RuntimeError(f"MT5 init failed: {mt5.last_error()}")

    print("[tawaqu3tickbridge] MT5 connected.")
    ok_symbols = ensure_symbols(SYMBOLS)
    if not ok_symbols:
        raise RuntimeError("No valid symbols. Fix SYMBOLS to match Market Watch.")

    # 1) push history once
    push_history(ok_symbols)

    last_candle_push = 0.0

    # Track last bar time sent per (symbol, tf) to reduce spam
    last_bar_time = {}  # (sym, tf_name) -> iso string

    while True:
        # ---- ticks loop
        for sym in ok_symbols:
            tick = get_tick(sym)
            if tick:
                post_json(POST_TICK, tick)

        # ---- candles loop
        now = time.time()
        if now - last_candle_push >= CANDLE_PUSH_EVERY_SEC:
            last_candle_push = now

            for sym in ok_symbols:
                for tf_name, tf_mt5 in TF_MAP.items():
                    candles = get_candles(sym, tf_mt5, CANDLES_LIMIT)
                    if not candles:
                        continue

                    last = candles[-1]
                    t_iso = datetime.fromtimestamp(last["t"]/1000, tz=timezone.utc).isoformat()

                    # Only push if bar time changed OR if we never pushed before.
                    # (If you want continuous updates, remove this if-block and rely on Node upsert.)
                    k = (sym, tf_name)
                    if last_bar_time.get(k) == t_iso:
                        continue
                    last_bar_time[k] = t_iso

                    post_json(POST_OHLC, {
                        "symbol": sym,
                        "tf": tf_name,
                        "time": t_iso,
                        "open": last["o"],
                        "high": last["h"],
                        "low":  last["l"],
                        "close": last["c"],
                        "volume": last.get("v", 0.0),
                    })

                    # OPTIONAL: demo signal (remove when model ready)
                    side = "BUY" if last["c"] > last["o"] else "SELL"
                    post_json(POST_SIGNAL, {
                        "symbol": sym,
                        "tf": tf_name,
                        "signal": side,
                        "meta": {"entry": last["c"], "score": 0.50, "note": "demo signal (replace with model)"},
                        "time": iso_now()
                    })

        time.sleep(TICK_SLEEP_SEC)

if __name__ == "__main__":
    main()
