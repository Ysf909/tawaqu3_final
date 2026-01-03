class Tick {
  final String symbol;

  /// Canonical naming used by server.js: bid/ask (+ mid)
  final double bid;
  final double ask;
  final double mid;

  /// Optional: some parts of the app call it "price"
  final double price;

  final DateTime time;

  Tick({
    required this.symbol,
    double? bid,
    double? ask,
    double? mid,
    double? price,

    // Backward-compat: old code sometimes used buy/sell
    double? buy,
    double? sell,

    DateTime? time,
  }) : bid = (bid ?? buy ?? 0.0),
       ask = (ask ?? sell ?? 0.0),
       mid = (mid ?? (((bid ?? buy ?? 0.0) + (ask ?? sell ?? 0.0)) / 2.0)),
       price =
           (price ??
           (mid ?? (((bid ?? buy ?? 0.0) + (ask ?? sell ?? 0.0)) / 2.0))),
       time = (time ?? DateTime.now().toUtc());

  // Backward-compat getters
  double get buy => bid;
  double get sell => ask;

  double get spread => ask - bid;

  factory Tick.fromJson(Map<String, dynamic> j) {
    final symbol = (j['symbol'] ?? '').toString();
    final bid = (j['bid'] as num?)?.toDouble() ?? 0.0;
    final ask = (j['ask'] as num?)?.toDouble() ?? 0.0;
    final mid = (j['mid'] as num?)?.toDouble() ?? ((bid + ask) / 2.0);
    final price = (j['price'] as num?)?.toDouble() ?? mid;

    final time =
        DateTime.tryParse((j['time'] ?? '').toString()) ??
        DateTime.now().toUtc();

    return Tick(
      symbol: symbol,
      bid: bid,
      ask: ask,
      mid: mid,
      price: price,
      time: time,
    );
  }
}
