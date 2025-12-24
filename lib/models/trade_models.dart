enum TradingType { long, short, scalper }

enum TradingModel { ict, smc, trend }

enum TradeOutcome { tpHit, slHit }

class InstrumentSpec {
  final double pipSize;
  final double pipValuePerLot; // value of 1 pip for 1.0 lot

  const InstrumentSpec({
    required this.pipSize,
    required this.pipValuePerLot,
  });
}

// You can tweak these per broker later if needed
InstrumentSpec specForPair(String pair) {
  switch (pair.toUpperCase()) {
    case 'XAUUSD':
      // 1 lot = 100 oz, 0.1 move ~ $10
      return const InstrumentSpec(
        pipSize: 0.1,
        pipValuePerLot: 10.0,
      );

    case 'EURUSD':
    case 'GBPUSD':
    case 'BTCUSD': // you'll probably treat crypto differently, see note below
      // For standard FX, 1 lot = 100k, 1 pip (0.0001) = $10
      return const InstrumentSpec(
        pipSize: 0.0001,
        pipValuePerLot: 10.0,
      );

    default:
      // fallback: treat as normal FX pair
      return const InstrumentSpec(
        pipSize: 0.0001,
        pipValuePerLot: 10.0,
      );
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
class TradeEntity {
  final String id;
  final String userId;
  final double entry;
  final double sl;
  final double tp;
  final double lot;
  final String school;
  final DateTime time;
  final DateTime createdAt;
  final TradeOutcome? outcome;   // 👈 new
  final double profit;           // optional, if you added profit column

  TradeEntity({
    required this.id,
    required this.userId,
    required this.entry,
    required this.sl,
    required this.tp,
    required this.lot,
    required this.school,
    required this.time,
    required this.createdAt,
    this.outcome,
    this.profit = 0,
  });

  TradeEntity copyWith({
    TradeOutcome? outcome,
    double? profit,
  }) {
    return TradeEntity(
      id: id,
      userId: userId,
      entry: entry,
      sl: sl,
      tp: tp,
      lot: lot,
      school: school,
      time: time,
      createdAt: createdAt,
      outcome: outcome ?? this.outcome,
      profit: profit ?? this.profit,
    );
  }

  factory TradeEntity.fromMap(Map<String, dynamic> map) {
    return TradeEntity(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      entry: (map['entry'] as num).toDouble(),
      sl: (map['sl'] as num?)?.toDouble() ?? 0,
      tp: (map['tp'] as num?)?.toDouble() ?? 0,
      lot: (map['lot'] as num?)?.toDouble() ?? 0,
      school: map['school'] as String? ?? '',
      time: DateTime.parse(map['time'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      outcome: fromDb(map['outcome'] as String?),
      profit: (map['profit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
