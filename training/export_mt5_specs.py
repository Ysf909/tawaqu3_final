import json
import MetaTrader5 as mt5

# Put your exact Market Watch names here (with suffix if your broker uses it)
SYMBOLS = ["XAUUSD_", "XAGUSD_", "EURUSD_", "BTCUSD", "ETHUSD"]

def pick_first_existing(cands):
    for s in cands:
        if mt5.symbol_select(s, True):
            return s
    return None

def main():
    if not mt5.initialize():
        raise SystemExit("MT5 init failed: " + str(mt5.last_error()))

    out = {}

    for sym in SYMBOLS:
        if not mt5.symbol_select(sym, True):
            # try without underscore suffix fallback
            alt = sym.replace("_","")
            if not mt5.symbol_select(alt, True):
                print("[skip] symbol_select failed:", sym)
                continue
            sym = alt

        info = mt5.symbol_info(sym)
        if info is None:
            print("[skip] symbol_info None:", sym)
            continue

        point = float(getattr(info, "point", 0.0) or 0.0)
        digits = int(getattr(info, "digits", 0) or 0)

        tick_size  = float(getattr(info, "trade_tick_size", 0.0) or 0.0)
        tick_value = float(getattr(info, "trade_tick_value", 0.0) or 0.0)
        contract   = float(getattr(info, "trade_contract_size", 0.0) or 0.0)

        # Fallbacks (some brokers leave trade_tick_size empty)
        if tick_size <= 0 and point > 0:
            tick_size = point

        # For CFDs/metals/crypto: treat "pip" == tick (most reliable)
        pip_size = tick_size
        pip_value = tick_value  # value of 1 tick for 1.0 lot

        out[sym] = {
            "digits": digits,
            "point": point,
            "tickSize": tick_size,
            "tickValuePerLot": tick_value,
            "pipSize": pip_size,
            "pipValuePerLot": pip_value,
            "contractSize": contract,
        }

    mt5.shutdown()

    print(json.dumps(out, indent=2))
    with open(r"assets\instrument_specs.json", "w", encoding="utf-8") as f:
        json.dump(out, f, indent=2)

if __name__ == "__main__":
    main()
