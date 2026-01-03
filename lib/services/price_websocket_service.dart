import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:tawaqu3_final/models/market_model.dart';
import 'package:tawaqu3_final/models/signal_msg.dart';
import 'package:tawaqu3_final/models/tick.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket client for:
/// - live ticks
/// - live candle updates
/// - bulk candle snapshots (get_candles)
/// - live signals
class PriceWebSocketService {
  /// Default WS URL for local development.
  ///
  /// - Android emulator must use 10.0.2.2 to reach your PC localhost.
  /// - Other platforms can use 127.0.0.1.
  static String get defaultWsUrl {
    if (kIsWeb) return 'ws://127.0.0.1:8080';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ws://10.0.2.2:8080';
      default:
        return 'ws://127.0.0.1:8080';
    }
  }

  /// Global shared instance
  static PriceWebSocketService instance = PriceWebSocketService();

  /// Change the URL used by the shared instance.
  static Future<void> configureInstance({required String wsUrl}) async {
    if (instance.wsUrl == wsUrl) return;
    try {
      await instance.disconnect();
    } catch (_) {}
    instance = PriceWebSocketService(wsUrl: wsUrl);
  }

  /// Normalize symbols so "XAUUSD_" and "XAUUSD" map to the same key.
  String _normSymbol(String s) {
    final raw = (s).toString().trim();
    if (raw.isEmpty) return raw;
    if (raw.endsWith('_')) return raw.substring(0, raw.length - 1);
    return raw;
  }

  String _key(String symbol, String tf) => '${_normSymbol(symbol)}__${tf.toLowerCase()}';

  final String wsUrl;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  // Streams
  final _ticksCtrl = StreamController<Tick>.broadcast();
  final _pricesCtrl = StreamController<Map<String, MarketPrice>>.broadcast();
  final _candlesCtrl = StreamController<CandleMsg>.broadcast();
  final _signalCtrl = StreamController<SignalMsg>.broadcast();

  // Cached snapshots
  final Map<String, MarketPrice> _prices = {};
  final Map<String, List<Candle>> _candles = {};

  // Pending candle requests
  final Map<String, Completer<List<Candle>>> _pendingCandles = {};

  // Live candle building from ticks
  final Map<String, Candle> _lastCandle = {};
  final Map<String, DateTime> _lastCandleStart = {};

  PriceWebSocketService({String? wsUrl}) : wsUrl = wsUrl ?? defaultWsUrl;

  Stream<Tick> get ticksStream => _ticksCtrl.stream;
  Stream<Map<String, MarketPrice>> get pricesStream => _pricesCtrl.stream;
  Stream<CandleMsg> get candlesStream => _candlesCtrl.stream;
  Stream<SignalMsg> get signalsStream => _signalCtrl.stream;

  bool get isConnected => _channel != null;

  List<Candle> candlesFor(String symbol, String tf) => getCandles(symbol, tf);

  List<Candle> getCandles(String symbol, String tf) {
    return List.unmodifiable(_candles[_key(symbol, tf)] ?? const []);
  }

  MarketPrice? getPrice(String symbol) => _prices[_normSymbol(symbol)];

  Future<void> connect() async {
    if (_channel != null) return;

    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _sub = _channel!.stream.listen(
      (event) {
        try {
          final m = jsonDecode(event.toString()) as Map<String, dynamic>;
          final type = (m['type'] ?? '').toString();

          if (type == 'tick') {
            _handleTick(m);
          } else if (type == 'candles' || type == 'ohlc') {
            _handleBulkCandles(m);
          } else if (type == 'candle') {
            _handleSingleCandle(m);
          } else if (type == 'signal') {
            _handleSignal(m);
          }
        } catch (_) {
          // ignore noisy frames
        }
      },
      onDone: () => disconnect(),
      onError: (_) => disconnect(),
      cancelOnError: true,
    );
  }

  Future<void> disconnect() async {
    try {
      await _sub?.cancel();
    } catch (_) {}
    _sub = null;

    try {
      await _channel?.sink.close(ws_status.normalClosure);
    } catch (_) {}
    _channel = null;
  }

  /// Request candle snapshot from server and wait for response.
  Future<List<Candle>> requestCandles(
    String symbol,
    String tf, {
    int limit = 600,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    await connect();

    final sym = _normSymbol(symbol);
    final k = _key(sym, tf);

    final existing = _pendingCandles[k];
    if (existing != null) return existing.future.timeout(timeout);

    final c = Completer<List<Candle>>();
    _pendingCandles[k] = c;

    _channel!.sink.add(jsonEncode({
      'type': 'get_candles',
      'symbol': sym,
      'tf': tf,
      'limit': limit,
    }));

    return c.future.timeout(timeout);
  }

  // ---------------- message handlers ----------------

  void _handleTick(Map<String, dynamic> m) {
    final symbol = _normSymbol((m['symbol'] ?? '').toString());
    final time = DateTime.tryParse((m['time'] ?? '').toString()) ?? DateTime.now().toUtc();

    final price = (m['price'] as num?)?.toDouble() ??
        (m['mid'] as num?)?.toDouble() ??
        (m['last'] as num?)?.toDouble() ??
        0.0;

    final bid = (m['bid'] as num?)?.toDouble() ?? price;
    final ask = (m['ask'] as num?)?.toDouble() ?? price;
    final mid = (m['mid'] as num?)?.toDouble() ?? ((bid + ask) / 2.0);

    final t = Tick.fromJson({
      'symbol': symbol,
      'bid': bid,
      'ask': ask,
      'mid': mid,
      'time': time.toIso8601String(),
      'price': price,
    });

    _ticksCtrl.add(t);

    // IMPORTANT: set `price` so Home page shows it
    _prices[symbol] = MarketPrice(
      symbol: symbol,
      buy: bid,
      sell: ask,
      mid: mid,
      time: time,
      price: price == 0.0 ? mid : price,
      change24h: (m['change24h'] as num?)?.toDouble(),
    );

    _pricesCtrl.add(Map.unmodifiable(_prices));

    // build candles locally for instant chart updates
    for (final tf in const ['1m', '5m', '15m', '1h']) {
      _buildLiveCandle(symbol, tf, t);
    }
  }

  void _handleSingleCandle(Map<String, dynamic> m) {
    final symbol = _normSymbol((m['symbol'] ?? '').toString());
    final tf = (m['tf'] ?? '').toString();
    if (symbol.isEmpty || tf.isEmpty) return;

    final candle = Candle(
      time: DateTime.tryParse((m['time'] ?? '').toString()) ?? DateTime.now().toUtc(),
      open: (m['open'] as num).toDouble(),
      high: (m['high'] as num).toDouble(),
      low: (m['low'] as num).toDouble(),
      close: (m['close'] as num).toDouble(),
      volume: (m['volume'] as num?)?.toDouble() ?? (m['v'] as num?)?.toDouble() ?? 0.0,
    );

    _appendCandle(symbol, tf, candle);
  }

  void _handleBulkCandles(Map<String, dynamic> m) {
    final symbol = _normSymbol((m['symbol'] ?? '').toString());
    final tf = (m['tf'] ?? '').toString();
    if (symbol.isEmpty || tf.isEmpty) return;

    final raw = (m['candles'] as List?) ?? const [];

    final candles = raw
        .cast<Map<String, dynamic>>()
        .map((e) {
          final time = DateTime.tryParse((e['time'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(
                (e['startTime'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
                isUtc: true,
              );

          return Candle(
            time: time.toUtc(),
            open: (e['open'] as num).toDouble(),
            high: (e['high'] as num).toDouble(),
            low: (e['low'] as num).toDouble(),
            close: (e['close'] as num).toDouble(),
            volume: (e['volume'] as num?)?.toDouble() ?? (e['v'] as num?)?.toDouble() ?? 0.0,
          );
        })
        .toList();

    final k = _key(symbol, tf);
    _candles[k] = _dedupeAndSort(candles);

    final pending = _pendingCandles.remove(k);
    if (pending != null && !pending.isCompleted) {
      pending.complete(List.unmodifiable(_candles[k]!));
    }

    if (_candles[k]!.isNotEmpty) {
      final last = _candles[k]!.last;
      _candlesCtrl.add(CandleMsg.fromCandle(symbol: symbol, tf: tf, c: last));
    }
  }

  void _handleSignal(Map<String, dynamic> m) {
    final symbol = _normSymbol((m['symbol'] ?? '').toString());
    final tf = (m['tf'] ?? '').toString();
    final entry = (m['entry'] as num?)?.toDouble();
    final score = (m['score'] as num?)?.toDouble();
    final side = (m['side'] ?? '').toString();
    final note = (m['note'] ?? '').toString();

    _signalCtrl.add(
      SignalMsg(
        symbol: symbol,
        tf: tf,
        side: side,
        entry: entry,
        score: score,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  // ---------------- candle helpers ----------------

  void _appendCandle(String symbol, String tf, Candle candle) {
    final k = _key(symbol, tf);
    final list = _candles[k] ?? <Candle>[];

    if (list.isNotEmpty) {
      final last = list.last;
      if (last.time.isAtSameMomentAs(candle.time)) {
        list[list.length - 1] = candle;
      } else if (candle.time.isAfter(last.time)) {
        list.add(candle);
      }
    } else {
      list.add(candle);
    }

    _candles[k] = _dedupeAndSort(list);
    _candlesCtrl.add(CandleMsg.fromCandle(symbol: _normSymbol(symbol), tf: tf, c: candle));
  }

  List<Candle> _dedupeAndSort(List<Candle> list) {
    list.sort((a, b) => a.time.compareTo(b.time));
    final out = <Candle>[];
    DateTime? lastTime;
    for (final c in list) {
      if (lastTime != null && c.time.isAtSameMomentAs(lastTime)) {
        out[out.length - 1] = c;
      } else {
        out.add(c);
        lastTime = c.time;
      }
    }
    return out;
  }

  DateTime _floorTime(DateTime t, String tf) {
    final s = tf.toLowerCase();
    Duration d;
    if (s == '1m') {
      d = const Duration(minutes: 1);
    } else if (s == '5m') {
      d = const Duration(minutes: 5);
    } else if (s == '15m') {
      d = const Duration(minutes: 15);
    } else if (s == '30m') {
      d = const Duration(minutes: 30);
    } else if (s == '1h') {
      d = const Duration(hours: 1);
    } else if (s == '4h') {
      d = const Duration(hours: 4);
    } else if (s == '1d') {
      d = const Duration(days: 1);
    } else {
      d = const Duration(minutes: 15);
    }

    final ms = d.inMilliseconds;
    final floored = (t.millisecondsSinceEpoch ~/ ms) * ms;
    return DateTime.fromMillisecondsSinceEpoch(floored, isUtc: true);
  }

  void _buildLiveCandle(String symbol, String tf, Tick tick) {
    final sym = _normSymbol(symbol);
    final k = _key(sym, tf);
    final start = _floorTime(tick.time.toUtc(), tf);

    final lastStart = _lastCandleStart[k];

    if (lastStart == null || start.isAfter(lastStart)) {
      final candle = Candle(
        time: start,
        open: tick.mid,
        high: tick.mid,
        low: tick.mid,
        close: tick.mid,
        volume: 0,
      );
      _lastCandleStart[k] = start;
      _lastCandle[k] = candle;
      _appendCandle(sym, tf, candle);
      return;
    }

    var candle = _lastCandle[k] ??
        Candle(
          time: start,
          open: tick.mid,
          high: tick.mid,
          low: tick.mid,
          close: tick.mid,
          volume: 0,
        );

    candle = Candle(
      time: candle.time,
      open: candle.open,
      high: tick.mid > candle.high ? tick.mid : candle.high,
      low: tick.mid < candle.low ? tick.mid : candle.low,
      close: tick.mid,
      volume: candle.volume,
    );

    _lastCandle[k] = candle;
    _appendCandle(sym, tf, candle);
  }

  void dispose() {
    disconnect();
    _ticksCtrl.close();
    _pricesCtrl.close();
    _candlesCtrl.close();
    _signalCtrl.close();
  }
}

class CandleMsg {
  final String symbol;
  final String tf;
  final DateTime time;
  final double open, high, low, close;

  CandleMsg({
    required this.symbol,
    required this.tf,
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory CandleMsg.fromCandle({
    required String symbol,
    required String tf,
    required Candle c,
  }) =>
      CandleMsg(
        symbol: symbol,
        tf: tf,
        time: c.time,
        open: c.open,
        high: c.high,
        low: c.low,
        close: c.close,
      );
}
