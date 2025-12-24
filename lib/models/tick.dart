class Tick {
  final String symbol;
  final double bid;
  final double ask;
  final DateTime time;

  Tick({
    required this.symbol,
    required this.bid,
    required this.ask,
    required this.time,
  });

  double get spread => ask - bid;

  factory Tick.fromJson(Map<String, dynamic> j) {
    return Tick(
      symbol: (j['symbol'] ?? '').toString(),
      bid: (j['bid'] as num).toDouble(),
      ask: (j['ask'] as num).toDouble(),
      time: DateTime.tryParse((j['time'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
