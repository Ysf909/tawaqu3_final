from datetime import datetime, timezone, timedelta
import MetaTrader5 as mt5

SYMBOLS = ["EURUSD_","XAUUSD_","BTCUSD","ETHUSD", "XAGUSD_"]

TF_MAP = {
  "1m":  mt5.TIMEFRAME_M1,
  "5m":  mt5.TIMEFRAME_M5,
  "15m": mt5.TIMEFRAME_M15,
  "30m": mt5.TIMEFRAME_M30,
  "1h":  mt5.TIMEFRAME_H1,
  "4h":  mt5.TIMEFRAME_H4,
  "1d":  mt5.TIMEFRAME_D1,
}

RANGE_DAYS = {
  "1m": 7,
  "5m": 60,
  "15m": 180,
  "30m": 180,
  "1h": 365,
  "4h": 730,
  "1d": 1095,

}

def main():
    if not mt5.initialize():
        raise RuntimeError(f"MT5 init failed: {mt5.last_error()}")

    print("[warmup] MT5 connected.")

    for s in SYMBOLS:
        mt5.symbol_select(s, True)

    now = datetime.now(timezone.utc)

    for sym in SYMBOLS:
        for tf_name, tf in TF_MAP.items():
            days = RANGE_DAYS[tf_name]
            d1 = now - timedelta(days=days)

            # Ask for a date range (this often forces MT5 to download history)
            rates = mt5.copy_rates_range(sym, tf, d1, now)

            n = 0 if rates is None else len(rates)
            print(f"[warmup] {sym} {tf_name} range({days}d) -> {n}")

            # Then check how many bars we can fetch from_pos (what your bridge uses)
            rates2 = mt5.copy_rates_from_pos(sym, tf, 0, 800)
            n2 = 0 if rates2 is None else len(rates2)
            print(f"[warmup] {sym} {tf_name} from_pos(800) -> {n2}")

    print("[warmup] done.")

if __name__ == "__main__":
    main()
