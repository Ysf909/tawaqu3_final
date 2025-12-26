import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:tawaqu3_final/models/market_model.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Unified WS client for:
/// - tick   (type: "tick")
/// - signal (type: "signal")
/// - candles:
///     a) batch OHLC (type: "ohlc", candles: [{t,o,h,l,c,v}, ...])
///     b) single candle (type: "candle" OR missing "type" but has open/high/low/close)
///
/// This is designed to tolerate different server payloads so your Flutter UI won't break
/// when you tweak the bridge server / MT5 EA.
class PriceWebSocketService {
  final String wsUrl;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  final _pricesCtrl = StreamController<Map<String, MarketPrice>>.broadcast();
  final _candlesCtrl = StreamController<Map<String, List<Candle>>>.broadcast(); // key: "$symbol__${tf}"
  final _signalsCtrl = StreamController<SignalMsg>.broadcast();

  Map<String, MarketPrice> _latestPrices = const {};
  Map<String, List<Candle>> _latestCandles = const {};

  Stream<Map<String, MarketPrice>> get pricesStream => _pricesCtrl.stream;
  Stream<Map<String, List<Candle>>> get candlesStream => _candlesCtrl.stream;
  Stream<SignalMsg> get signalsStream => _signalsCtrl.stream;

  PriceWebSocketService({
    // NOTE:
    // - Flutter web on same PC: ws://127.0.0.1:8080
    // - Android emulator: ws://10.0.2.2:8080
    // - Physical phone: ws://<YOUR_PC_LAN_IP>:8080
    this.wsUrl = 'ws://127.0.0.1:8080',
  }) {
    _connect();
  }

  List<Candle> candlesFor(String symbol, String tf) {
    final key = '${symbol.toUpperCase()}__${tf.toLowerCase()}';
    return _latestCandles[key] ?? const [];
  }

  MarketPrice? priceFor(String symbol) => _latestPrices[symbol.toUpperCase()];

  void _connect() {
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _sub = _channel!.stream.listen(
      (data) {
        try {
          final m = jsonDecode(data as String) as Map<String, dynamic>;
          final String type = (m['type'] ?? '').toString();

          if (type == 'tick') {
            _handleTick(m);
            return;
          }

          if (type == 'signal') {
            _signalsCtrl.add(SignalMsg.fromJson(m));
            return;
          }

          // Batch candles
          if (type == 'ohlc' && m['candles'] is List) {
            _handleOhlcBatch(m);
            return;
          }

          // Single candle (tolerant parsing)
          if (type == 'candle' || _looksLikeSingleCandle(m)) {
            _handleSingleCandle(m);
            return;
          }
        } catch (_) {
          // ignore bad payload
        }
      },
      onError: (_) {},
      onDone: () {},
    );
  }

  void _handleTick(Map<String, dynamic> m) {
    final symbol = (m['symbol'] ?? '').toString().toUpperCase();

    final mid = (m['mid'] as num?)?.toDouble() ??
        (((m['bid'] as num).toDouble() + (m['ask'] as num).toDouble()) / 2.0);

    _latestPrices = Map<String, MarketPrice>.from(_latestPrices);
    _latestPrices[symbol] = MarketPrice(
      price: mid,
      change24h: _latestPrices[symbol]?.change24h,
    );
    _pricesCtrl.add(_latestPrices);
  }

  void _handleOhlcBatch(Map<String, dynamic> m) {
    final symbol = (m['symbol'] ?? '').toString().toUpperCase();
    final tf = (m['tf'] ?? '').toString().toLowerCase();

    final list = (m['candles'] as List).cast<Map<String, dynamic>>();
    final candles = list.map((e) => Candle.fromJson(e)).toList(growable: false);

    final key = '${symbol}__${tf}';
    _latestCandles = Map<String, List<Candle>>.from(_latestCandles);
    _latestCandles[key] = candles;
    _candlesCtrl.add(_latestCandles);
  }

  bool _looksLikeSingleCandle(Map<String, dynamic> m) {
    final hasOhlc = (m.containsKey('open') || m.containsKey('o')) &&
        (m.containsKey('high') || m.containsKey('h')) &&
        (m.containsKey('low') || m.containsKey('l')) &&
        (m.containsKey('close') || m.containsKey('c'));
    final hasSymbolTf = m.containsKey('symbol') && m.containsKey('tf');
    return hasOhlc && hasSymbolTf;
  }

  void _handleSingleCandle(Map<String, dynamic> m) {
    final symbol = (m['symbol'] ?? '').toString().toUpperCase();
    final tf = (m['tf'] ?? '').toString().toLowerCase();
    final key = '${symbol}__${tf}';

    DateTime t;
    if (m['t'] != null) {
      // ms epoch
      t = DateTime.fromMillisecondsSinceEpoch((m['t'] as num).toInt(), isUtc: true);
    } else if (m['time'] != null) {
      t = DateTime.tryParse(m['time'].toString()) ?? DateTime.now().toUtc();
    } else {
      t = DateTime.now().toUtc();
    }

    double numVal(dynamic v) => (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;

    final candle = Candle(
      time: t,
      open: numVal(m['open'] ?? m['o']),
      high: numVal(m['high'] ?? m['h']),
      low: numVal(m['low'] ?? m['l']),
      close: numVal(m['close'] ?? m['c']),
      volume: numVal(m['volume'] ?? m['v']),
    );

    _latestCandles = Map<String, List<Candle>>.from(_latestCandles);
    final prev = List<Candle>.from(_latestCandles[key] ?? const []);
    prev.add(candle);

    // keep chronological and bounded (last 600)
    prev.sort((a, b) => a.time.compareTo(b.time));
    if (prev.length > 600) {
      prev.removeRange(0, prev.length - 600);
    }

    _latestCandles[key] = prev;
    _candlesCtrl.add(_latestCandles);
  }

  void dispose() {
    _sub?.cancel();
    _channel?.sink.close(ws_status.goingAway);
    _pricesCtrl.close();
    _candlesCtrl.close();
    _signalsCtrl.close();
  }
}
