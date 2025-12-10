
import 'package:tawaqu3_final/models/trade_models.dart';
class HistoryTrade {
  final String id;         // uuid
  final String tradeId;    // uuid (FK to trades.id)
  final double? previousEntry;
  final double? previousSl;
  final double? previousTp;
  final double? previousLot;
  final DateTime dateSaved;
  final TradeOutcome? outcome;
  
  HistoryTrade({
    required this.id,
    required this.tradeId,
    this.previousEntry,
    this.previousSl,
    this.previousTp,
    this.previousLot,
    required this.dateSaved,
    required this.outcome,
  });

  factory HistoryTrade.fromMap(Map<String, dynamic> map) {
    return HistoryTrade(
      id: map['id'] as String,
      tradeId: map['trade_id'] as String,
      previousEntry: (map['previous_entry'] as num?)?.toDouble(),
      previousSl: (map['previous_sl'] as num?)?.toDouble(),
      previousTp: (map['previous_tp'] as num?)?.toDouble(),
      previousLot: (map['previous_lot'] as num?)?.toDouble(),
      dateSaved: DateTime.parse(map['date_saved'] as String),
      outcome:fromDb(map['outcome'] as String?),
    );
  }
}
