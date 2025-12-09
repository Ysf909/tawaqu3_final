class HistoryTrade {
  final int? id;
  final String userId;
  final String tradeId;
  final double previousEntry;
  final double previousSl;
  final double previousTp;
  final double previousLot;
  final DateTime dateSaved;

  HistoryTrade({
    this.id,
    required this.userId,
    required this.tradeId,
    required this.previousEntry,
    required this.previousSl,
    required this.previousTp,
    required this.previousLot,
    required this.dateSaved,
  });

  factory HistoryTrade.fromMap(Map<String, dynamic> map) {
    return HistoryTrade(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      tradeId: map['trade_id'] as String,
      previousEntry: (map['previous_entry'] as num).toDouble(),
      previousSl: (map['previous_sl'] as num).toDouble(),
      previousTp: (map['previous_tp'] as num).toDouble(),
      previousLot: (map['previous_lot'] as num).toDouble(),
      dateSaved: DateTime.parse(map['date_saved'] as String),
    );
  }
}
