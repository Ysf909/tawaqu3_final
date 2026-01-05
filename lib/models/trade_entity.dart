import 'package:tawaqu3_final/models/trade_models.dart';

class TradeEntity {
  final String id; // uuid from Supabase
  final String userId;

  final String? pair;
  final String? side;
  final double? confidence;

  final double entry;
  final double sl;
  final double tp;
  final double lot;

  final String school;
  final DateTime time;
  final DateTime createdAt;

  final TradeOutcome? outcome;
  final double profit;

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
    this.pair,
    this.side,
    this.confidence,
    this.outcome,
    this.profit = 0.0,
  });

  factory TradeEntity.fromMap(Map<String, dynamic> map) {
    return TradeEntity(
      id: (map['id'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      pair: (map['pair'] as String?),
      side: (map['side'] as String?),
      confidence: (map['confidence'] as num?)?.toDouble(),
      entry: (map['entry'] as num?)?.toDouble() ?? 0.0,
      sl: (map['sl'] as num?)?.toDouble() ?? 0.0,
      tp: (map['tp'] as num?)?.toDouble() ?? 0.0,
      lot: (map['lot'] as num?)?.toDouble() ?? 0.0,
      school: (map['school'] as String?) ?? '',
      time:
          DateTime.tryParse((map['time'] ?? '').toString()) ??
          DateTime.now().toUtc(),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now().toUtc(),
      outcome: fromDb(map['outcome'] as String?),
      profit: (map['profit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
