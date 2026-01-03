import 'trade_models.dart';

extension TradingTypeLabelX on TradingType {
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

extension TradingModelLabelX on TradingModel {
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
