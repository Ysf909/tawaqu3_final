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

  void _putPrice(String symbol, double mid) {
    final s1 = symbol.toUpperCase();
    final s2 = _alias(s1);

    _latestPrices = Map<String, MarketPrice>.from(_latestPrices);

    _latestPrices[s1] =
        MarketPrice(price: mid, change24h: _latestPrices[s1]?.change24h);

    if (s2 != s1) {
      _latestPrices[s2] =
          MarketPrice(price: mid, change24h: _latestPrices[s2]?.change24h);
    }

    _pricesCtrl.add(_latestPrices);
  }

  void _setCandles(String symbol, String tf, List<Candle> candles) {
    final s1 = symbol.toUpperCase();
    final s2 = _alias(s1);

    _latestCandles = Map<String, List<Candle>>.from(_latestCandles);

    _latestCandles[_key(s1, tf)] = candles;
    if (s2 != s1) _latestCandles[_key(s2, tf)] = candles;

    _candlesCtrl.add(_latestCandles);
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

            final mid = (m['mid'] as num?)?.toDouble() ??
                ((((m['bid'] as num).toDouble()) + ((m['ask'] as num).toDouble())) /
                    2.0);

            _putPrice(symbol, mid);
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
          } else if (type == 'ohlc') {
            // keep compatibility if you later send bulk candles
            final symbol = (m['symbol'] ?? '').toString();
            final tf = (m['tf'] ?? '').toString();
            if (symbol.isEmpty || tf.isEmpty) return;

            final list = (m['candles'] as List).cast<Map<String, dynamic>>();
            final candles =
                list.map((e) => Candle.fromJson(e)).toList(growable: false);

            _setCandles(symbol, tf, candles);
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

