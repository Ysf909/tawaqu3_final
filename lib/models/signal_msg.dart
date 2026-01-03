class SignalMsg {
  final String symbol;
  final String tf;

  /// "BUY" / "SELL" (optional; default empty for backward compatibility)
  final String side;

  final double? entry;
  final double? score;
  final String? note;

  const SignalMsg({
    required this.symbol,
    required this.tf,
    this.side = '',
    this.entry,
    this.score,
    this.note,
  });

  factory SignalMsg.fromJson(Map<String, dynamic> j) => SignalMsg(
        symbol: (j['symbol'] ?? '').toString(),
        tf: (j['tf'] ?? '').toString(),
        side: (j['side'] ?? j['action'] ?? '').toString().toUpperCase(),
        entry: (j['entry'] as num?)?.toDouble(),
        score: (j['score'] as num?)?.toDouble(),
        note: ((j['note'] ?? '').toString().trim().isEmpty)
            ? null
            : (j['note'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'tf': tf,
        'side': side,
        'entry': entry,
        'score': score,
        'note': note,
      };
}
