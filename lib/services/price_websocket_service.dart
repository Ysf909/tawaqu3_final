import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:tawaqu3_final/models/market_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

class PriceWebSocketService {
  final String wsUrl;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  final _pricesCtrl = StreamController<Map<String, MarketPrice>>.broadcast();
  final _candlesCtrl = StreamController<Map<String, List<Candle>>>.broadcast(); // key: "$symbol__$tf"
  final _signalsCtrl = StreamController<SignalMsg>.broadcast();

  Map<String, MarketPrice> _latestPrices = {};
  Map<String, List<Candle>> _latestCandles = {};

  // Track which TFs we have candle history for (so we can update them live from ticks)
  final Map<String, Set<String>> _loadedTfsBySymbol = {};

  // Pending candle requests: key("SYMBOL__tf") -> completer
  final Map<String, Completer<List<Candle>>> _pendingCandleRequests = {};

  Stream<Map<String, MarketPrice>> get pricesStream => _pricesCtrl.stream;
  Stream<Map<String, List<Candle>>> get candlesStream => _candlesCtrl.stream;
  Stream<SignalMsg> get signalsStream => _signalsCtrl.stream;

  PriceWebSocketService({String? wsUrl}) : wsUrl = wsUrl ?? _defaultWsUrl() {
    _connect();
  }

  static String _defaultWsUrl() {
    // Web (Chrome on PC)
    if (kIsWeb) return 'ws://127.0.0.1:8080';
    // Android emulator -> host PC
    return 'ws://10.0.2.2:8080';
  }

  static String _alias(String s) =>
      s.endsWith('_') ? s.substring(0, s.length - 1) : s;

  static String _key(String symbol, String tf) =>
      '${symbol.toUpperCase()}__${tf.toString()}';

  List<Candle> candlesFor(String symbol, String tf) {
    return _latestCandles[_key(symbol, tf)] ?? const <Candle>[];
  }

  void _putPrice(String symbol, double mid, {double? change24h}) {
    final s1 = symbol.toUpperCase();
    final s2 = _alias(s1);

    _latestPrices = Map<String, MarketPrice>.from(_latestPrices);

    _latestPrices[s1] = MarketPrice(
      price: mid,
      change24h: change24h ?? _latestPrices[s1]?.change24h,
    );

    if (s2 != s1) {
      _latestPrices[s2] = MarketPrice(
        price: mid,
        change24h: change24h ?? _latestPrices[s2]?.change24h,
      );
    }

    _pricesCtrl.add(_latestPrices);
  }

  void _setCandles(String symbol, String tf, List<Candle> candles) {
    final s1 = symbol.toUpperCase();
    final s2 = _alias(s1);

    // remember that this symbol has this TF loaded
    final tfKey = tf.toLowerCase();
    _loadedTfsBySymbol.putIfAbsent(s1, () => <String>{}).add(tfKey);
    if (s2 != s1) {
      _loadedTfsBySymbol.putIfAbsent(s2, () => <String>{}).add(tfKey);
    }

    _latestCandles = Map<String, List<Candle>>.from(_latestCandles);

    _latestCandles[_key(s1, tf)] = candles;
    if (s2 != s1) _latestCandles[_key(s2, tf)] = candles;

    _candlesCtrl.add(_latestCandles);

    // complete pending request(s)
    final k1 = _key(s1, tfKey);
    final k2 = _key(s2, tfKey);
    final c1 = _pendingCandleRequests.remove(k1);
    c1?.complete(candles);
    if (s2 != s1) {
      final c2 = _pendingCandleRequests.remove(k2);
    
      // don't double-complete the same candles list
      if (c2 != null && !c2.isCompleted) c2.complete(candles);
    }
  }

  int _tfSeconds(String tf) {
    final s = tf.toLowerCase();
    if (s == '1m') return 60;
    if (s == '5m') return 300;
    if (s == '15m') return 900;
    if (s == '1h') return 3600;
    if (s == '4h') return 14400;
    if (s == '1d') return 86400;
    return 900;
  }

  DateTime _floorToTf(DateTime t, String tf) {
    final sec = _tfSeconds(tf);
    final ms = t.millisecondsSinceEpoch;
    final startMs = (ms ~/ 1000 ~/ sec) * sec * 1000;
    return DateTime.fromMillisecondsSinceEpoch(startMs, isUtc: true);
  }

  void _updateLiveCandlesFromTick(String symbol, String tf, double price, DateTime tickTime) {
    final s1 = symbol.toUpperCase();
    final s2 = _alias(s1);
    final tfKey = tf.toLowerCase();

    void updateForSym(String sym) {
      final k = _key(sym, tfKey);
      final prev = _latestCandles[k];
      if (prev == null || prev.isEmpty) return;

      final start = _floorToTf(tickTime, tfKey);
      final last = prev.last;
      final lastStart = _floorToTf(last.time, tfKey);

      final next = List<Candle>.from(prev);

      if (lastStart != start) {
        // new candle
        next.add(Candle(
          time: start,
          open: price,
          high: price,
          low: price,
          close: price,
          volume: 0.0,
        ));
      } else {
        // update existing candle (immutable -> replace)
        next[next.length - 1] = Candle(
          time: last.time,
          open: last.open,
          high: (price > last.high) ? price : last.high,
          low: (price < last.low) ? price : last.low,
          close: price,
          volume: last.volume,
        );
      }

      // keep last 600 candles
      if (next.length > 600) {
        next.removeRange(0, next.length - 600);
      }

      _latestCandles[k] = next;
    }

    _latestCandles = Map<String, List<Candle>>.from(_latestCandles);
    updateForSym(s1);
    if (s2 != s1) updateForSym(s2);
    _candlesCtrl.add(_latestCandles);
  }

  void sendJson(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (_) {
      // ignore
    }
  }

  void subscribeSymbol(String symbol) {
    sendJson({'type': 'subscribe', 'symbol': symbol});
  }

  void unsubscribeSymbol(String symbol) {
    sendJson({'type': 'unsubscribe', 'symbol': symbol});
  }

  Future<List<Candle>> requestCandles(
    String symbol,
    String tf, {
    int limit = 200,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final tfKey = tf.toLowerCase();
    final k = _key(symbol, tfKey);
    final completer = Completer<List<Candle>>();

    // overwrite any older pending request for the same key
    _pendingCandleRequests[k] = completer;

    sendJson({
      'type': 'get_candles',
      'symbol': symbol,
      'tf': tfKey,
      'limit': limit,
    });

    try {
      return await completer.future.timeout(timeout);
    } catch (_) {
      _pendingCandleRequests.remove(k);
      return candlesFor(symbol, tfKey);
    }
  }

  void _appendCandle(String symbol, String tf, Candle candle) {
    final s1 = symbol.toUpperCase();
    final s2 = _alias(s1);

    _latestCandles = Map<String, List<Candle>>.from(_latestCandles);

    void appendOne(String sym) {
      final k = _key(sym, tf);
      final prev = _latestCandles[k] ?? const <Candle>[];
      final next = List<Candle>.from(prev)..add(candle);

      // keep last 600 candles
      if (next.length > 600) {
        next.removeRange(0, next.length - 600);
      }

      _latestCandles[k] = next;
    }

    appendOne(s1);
    if (s2 != s1) appendOne(s2);

    _candlesCtrl.add(_latestCandles);
  }

  void _connect() {
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _sub = _channel!.stream.listen(
      (data) {
        try {
          final str = data is String ? data : data.toString();
          final m = jsonDecode(str) as Map<String, dynamic>;
          final type = (m['type'] ?? '').toString();

          if (type == 'tick') {
            final symbol = (m['symbol'] ?? '').toString();
            if (symbol.isEmpty) return;

            final mid = (m['price'] as num?)?.toDouble() ??
                (m['mid'] as num?)?.toDouble() ??
                (((m['bid'] as num?)?.toDouble() ?? 0.0) +
                        ((m['ask'] as num?)?.toDouble() ?? 0.0)) /
                    2.0;

            final change24h = (m['change24h'] as num?)?.toDouble();
            final tickTime = DateTime.tryParse((m['time'] ?? '').toString()) ??
                DateTime.now().toUtc();

            _putPrice(symbol, mid, change24h: change24h);

            // Turn ticks into live candles for any TF that already has history
            final s1 = symbol.toUpperCase();
            final s2 = _alias(s1);
            final tfs = <String>{
              ...(_loadedTfsBySymbol[s1] ?? const <String>{}),
              ...(_loadedTfsBySymbol[s2] ?? const <String>{}),
            };
            for (final tf in tfs) {
              _updateLiveCandlesFromTick(symbol, tf, mid, tickTime);
            }
          } else if (type == 'candle') {
            final symbol = (m['symbol'] ?? '').toString();
            final tf = (m['tf'] ?? '').toString();
            if (symbol.isEmpty || tf.isEmpty) return;

            final candle = Candle(
              time: DateTime.tryParse((m['time'] ?? '').toString()) ??
                  DateTime.now().toUtc(),
              open: (m['open'] as num).toDouble(),
              high: (m['high'] as num).toDouble(),
              low: (m['low'] as num).toDouble(),
              close: (m['close'] as num).toDouble(),
              volume: (m['volume'] as num?)?.toDouble() ?? (m['v'] as num?)?.toDouble() ?? 0.0,
            );

            _appendCandle(symbol, tf, candle);
          } else if (type == 'candles' || type == 'ohlc') {
            // bulk candles
            final symbol = (m['symbol'] ?? '').toString();
            final tf = (m['tf'] ?? '').toString();
            if (symbol.isEmpty || tf.isEmpty) return;

            final raw = (m['candles'] as List?) ?? const [];
            final list = raw.cast<Map<String, dynamic>>();
            final candles = list
                .map((e) => Candle.fromJson(e))
                .toList(growable: false);

            _setCandles(symbol, tf.toLowerCase(), candles);
          } else if (type == 'signal') {
            _signalsCtrl.add(SignalMsg.fromJson(m));
          }
        } catch (_) {
          // ignore bad payload
        }
      },
      onError: (_) {},
      onDone: () {},
    );
  }

  void dispose() {
    _sub?.cancel();
    _channel?.sink.close(ws_status.goingAway);
    _pricesCtrl.close();
    _candlesCtrl.close();
    _signalsCtrl.close();
  }
}

