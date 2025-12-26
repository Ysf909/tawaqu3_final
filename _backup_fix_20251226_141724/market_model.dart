class MarketPrice {
  final double price;
  final double? change24h; // optional
  const MarketPrice({required this.price, this.change24h});
}

class TickMsg {
  final String symbol;
  final double bid;
  final double ask;
  final double mid;
  final DateTime time;

  TickMsg({
    required this.symbol,
    required this.bid,
    required this.ask,
    required this.mid,
    required this.time,
  });
}

class Candle {
  final DateTime time;
  final double open, high, low, close;
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
        time: DateTime.fromMillisecondsSinceEpoch((j["t"] as num).toInt(), isUtc: true),
        open: (j["o"] as num).toDouble(),
        high: (j["h"] as num).toDouble(),
        low: (j["l"] as num).toDouble(),
        close: (j["c"] as num).toDouble(),
        volume: (j["v"] as num?)?.toDouble() ?? 0,
      );
}

class SignalMsg {
  final String symbol;
  final String tf;
  final String side; // BUY/SELL/NONE
  final double? entry, sl, tp, score;
  final String? note;
  final DateTime time;

  SignalMsg({
    required this.symbol,
    required this.tf,
    required this.side,
    required this.time,
    this.entry,
    this.sl,
    this.tp,
    this.score,
    this.note,
  });

  factory SignalMsg.fromJson(Map<String, dynamic> j) => SignalMsg(
        symbol: (j["symbol"] ?? "").toString(),
        tf: (j["tf"] ?? "").toString(),
        side: (j["side"] ?? "NONE").toString(),
        entry: (j["entry"] as num?)?.toDouble(),
        sl: (j["sl"] as num?)?.toDouble(),
        tp: (j["tp"] as num?)?.toDouble(),
        score: (j["score"] as num?)?.toDouble(),
        note: (j["note"] ?? "")?.toString(),
        time: DateTime.tryParse((j["time"] ?? "").toString()) ?? DateTime.now().toUtc(),
      );
}
