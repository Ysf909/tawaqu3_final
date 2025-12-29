class TradeEntity {
  final String id; // uuid from Supabase
  final String userId; // uuid from your users table
  final double entry;
  final double sl;
  final double tp;
  final double lot;
  final String school;
  final DateTime time;
  final DateTime createdAt;

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
  });

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
    );
  }
}
