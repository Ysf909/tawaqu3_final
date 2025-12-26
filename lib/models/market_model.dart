class MarketPrice {
  final double price;
  final double? change24h;
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

  factory TickMsg.fromJson(Map<String, dynamic> j) {
    final bid = (j["bid"] as num?)?.toDouble() ?? 0.0;
    final ask = (j["ask"] as num?)?.toDouble() ?? 0.0;
    final mid = (j["mid"] as num?)?.toDouble() ?? ((bid + ask) / 2.0);
    final t = j["time"];
    final time = (t is String)
        ? (DateTime.tryParse(t) ?? DateTime.now().toUtc())
        : DateTime.now().toUtc();

    return TickMsg(
      symbol: (j["symbol"] ?? "").toString(),
      bid: bid,
      ask: ask,
      mid: mid,
      time: time,
    );
  }
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

  /// Supports:
  /// A) {t,o,h,l,c,v} (numbers)
  /// B) {time,open,high,low,close,volume} (time may be ISO string)
  factory Candle.fromJson(Map<String, dynamic> j) {
    DateTime parseTime() {
      final t = j["time"] ?? j["t"];
      if (t is String) return DateTime.tryParse(t) ?? DateTime.now().toUtc();
      if (t is num) {
        // if seconds: < 10^12; if ms: >= 10^12
        final v = t.toInt();
        final ms = v < 1000000000000 ? v * 1000 : v;
        return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
      }
      return DateTime.now().toUtc();
    }

    double pick(String a, String b) =>
        (j[a] as num?)?.toDouble() ?? (j[b] as num?)?.toDouble() ?? 0.0;

    return Candle(
      time: parseTime(),
      open: pick("open", "o"),
      high: pick("high", "h"),
      low: pick("low", "l"),
      close: pick("close", "c"),
      volume: (j["volume"] as num?)?.toDouble() ?? (j["v"] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SignalMsg {
  final String symbol;
  final String tf;
  final String side; // BUY/SELL/NONE
  final double? entry;
  final double? sl;
  final double? tp;
  final double? score;
  final String? note;
  final DateTime time;

  SignalMsg({
    required this.symbol,
    required this.tf,
    required this.side,
    this.entry,
    this.sl,
    this.tp,
    this.score,
    this.note,
    required this.time,
  });

  /// Supports:
  /// A) {type:'signal', side:'BUY', entry:..., score:..., note:...}
  /// B) {type:'signal', signal:'BUY', meta:{entry,score,note}, time:'ISO'}
  factory SignalMsg.fromJson(Map<String, dynamic> j) {
    final meta = (j["meta"] is Map) ? Map<String, dynamic>.from(j["meta"]) : <String, dynamic>{};

    String pickSide() => (j["side"] ?? j["signal"] ?? j["action"] ?? "NONE").toString();

    num? pickNum(String k) => (j[k] as num?) ?? (meta[k] as num?);

    String? pickStr(String k) => (j[k]?.toString().isNotEmpty == true)
        ? j[k].toString()
        : (meta[k]?.toString());

    final t = j["time"];
    final time = (t is String)
        ? (DateTime.tryParse(t) ?? DateTime.now().toUtc())
        : DateTime.now().toUtc();

    return SignalMsg(
      symbol: (j["symbol"] ?? "").toString(),
      tf: (j["tf"] ?? "").toString(),
      side: pickSide(),
      entry: pickNum("entry")?.toDouble(),
      sl: pickNum("sl")?.toDouble(),
      tp: pickNum("tp")?.toDouble(),
      score: pickNum("score")?.toDouble(),
      note: pickStr("note"),
      time: time,
    );
  }
}
