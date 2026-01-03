class MarketPrice {
  /// Symbol (optional). Example: XAUUSD
  final String? symbol;

  /// Bid/Ask (optional)
  final double? buy;
  final double? sell;

  /// Mid (optional). If null, you can derive it from [buy]/[sell] or [price].
  final double? mid;

  /// Server timestamp (optional)
  final DateTime? time;

  /// Single price value (optional). Many parts of the app use this as "mid".
  final double? price;

  /// 24h change percent/value (optional)
  final double? change24h;

  const MarketPrice({
    this.symbol,
    this.buy,
    this.sell,
    this.mid,
    this.time,
    this.price,
    this.change24h,
  });

  double get effectiveMid {
    if (mid != null) return mid!;
    if (price != null) return price!;
    if (buy != null && sell != null) return (buy! + sell!) / 2.0;
    return 0.0;
  }
}

class TickMsg {
  final String symbol;
  final DateTime time;
  final double bid;
  final double ask;

  TickMsg({
    required this.symbol,
    required this.time,
    required this.bid,
    required this.ask,
  });

  factory TickMsg.fromJson(Map<String, dynamic> j) => TickMsg(
        symbol: (j['symbol'] ?? '').toString(),
        time: DateTime.tryParse((j['time'] ?? '').toString()) ??
            DateTime.now().toUtc(),
        bid: (j['bid'] as num?)?.toDouble() ?? 0.0,
        ask: (j['ask'] as num?)?.toDouble() ?? 0.0,
      );
}

class Candle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory Candle.fromJson(Map<String, dynamic> j) => Candle(
        time: DateTime.tryParse((j['time'] ?? '').toString()) ??
            DateTime.now().toUtc(),
        open: (j['open'] as num?)?.toDouble() ?? 0.0,
        high: (j['high'] as num?)?.toDouble() ?? 0.0,
        low: (j['low'] as num?)?.toDouble() ?? 0.0,
        close: (j['close'] as num?)?.toDouble() ?? 0.0,
        volume: (j['volume'] as num?)?.toDouble() ?? 0.0,
      );
}
