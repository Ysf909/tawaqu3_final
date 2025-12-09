enum TradingType { long, short, scalper }

enum TradingModel { ict, smc, trend }

extension TradingTypeLabel on TradingType {
  String get label {
    switch (this) {
      case TradingType.long:
        return 'Long';
      case TradingType.short:
        return 'Short';
      case TradingType.scalper:
        return 'Scalper';
    }
  }
}

extension TradingModelLabel on TradingModel {
  String get label {
    switch (this) {
      case TradingModel.ict:
        return 'ICT';
      case TradingModel.smc:
        return 'SMC';
      case TradingModel.trend:
        return 'Trend';
    }
  }
}


/// Business rule: each type has ONE fixed model
TradingModel modelForType(TradingType type) {
  switch (type) {
    case TradingType.long:
      // Long → Trend model
      return TradingModel.trend;

    case TradingType.short:
      // Short → SMC (locked, as you requested)
      return TradingModel.smc;

    case TradingType.scalper:
      // Scalper → ICT model
      return TradingModel.ict;
  }
}
