enum TradingType { long, short, scalper }

enum TradingModel { ict, smc, trend }

enum TradeOutcome { tpHit, slHit }

class InstrumentSpec {
  final double pipSize;
  final double pipValuePerLot;

  const InstrumentSpec({required this.pipSize, required this.pipValuePerLot});
}

InstrumentSpec specForPair(String pair) {
  switch (pair.toUpperCase()) {
    case 'XAUUSD':
      return const InstrumentSpec(pipSize: 0.1, pipValuePerLot: 10.0);
    case 'XAGUSD':
      return const InstrumentSpec(pipSize: 0.01, pipValuePerLot: 5.0);
    case 'EURUSD':
    case 'ETHUSD':
    case 'BTCUSD':
      return const InstrumentSpec(pipSize: 0.0001, pipValuePerLot: 10.0);
    default:
      return const InstrumentSpec(pipSize: 0.0001, pipValuePerLot: 10.0);
  }
}

extension TradeOutcomeX on TradeOutcome {
  String get dbValue {
    switch (this) {
      case TradeOutcome.tpHit:
        return 'tp_hit';
      case TradeOutcome.slHit:
        return 'sl_hit';
    }
  }

  String get label {
    switch (this) {
      case TradeOutcome.tpHit:
        return 'TP hit';
      case TradeOutcome.slHit:
        return 'SL hit';
    }
  }
}

TradeOutcome? fromDb(String? value) {
  switch (value) {
    case 'tp_hit':
      return TradeOutcome.tpHit;
    case 'sl_hit':
      return TradeOutcome.slHit;
    default:
      return null;
  }
}

/// TEMP: only ICT is enabled until SMC/Trend models are ready
TradingModel modelForType(TradingType type) {
  switch (type) {
    case TradingType.scalper:
      return TradingModel.ict;
    case TradingType.short:
      return TradingModel.smc;
    case TradingType.long:
      return TradingModel.trend;
  }
}

