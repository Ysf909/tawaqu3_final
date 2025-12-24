import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_service.dart' show MarketPrice;

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

  factory CandleMsg.fromJson(Map<String, dynamic> j) => CandleMsg(
        symbol: (j['symbol'] ?? '').toString(),
        tf: (j['tf'] ?? '').toString(),
        time: DateTime.tryParse((j['time'] ?? '').toString()) ?? DateTime.now().toUtc(),
        open: (j['open'] as num).toDouble(),
        high: (j['high'] as num).toDouble(),
        low: (j['low'] as num).toDouble(),
        close: (j['close'] as num).toDouble(),
      );
}

class SignalMsg {
  final String symbol;
  final String tf;
  final DateTime time;
  final dynamic output;
  final Map<String, dynamic>? meta;

  SignalMsg({
    required this.symbol,
    required this.tf,
    required this.time,
    required this.output,
    required this.meta,
  });

  factory SignalMsg.fromJson(Map<String, dynamic> j) => SignalMsg(
        symbol: (j['symbol'] ?? '').toString(),
        tf: (j['tf'] ?? '').toString(),
        time: DateTime.tryParse((j['time'] ?? '').toString()) ?? DateTime.now().toUtc(),
        output: j['output'],
        meta: (j['meta'] is Map<String, dynamic>) ? (j['meta'] as Map<String, dynamic>) : null,
      );
}

class PriceWebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  final _pricesController = StreamController<Map<String, MarketPrice>>.broadcast();
  final _candleController = StreamController<CandleMsg>.broadcast();
  final _signalController = StreamController<SignalMsg>.broadcast();

  final Map<String, MarketPrice> _latest = {};

  Stream<Map<String, MarketPrice>> get pricesStream => _pricesController.stream;
  Stream<CandleMsg> get candleStream => _candleController.stream;
  Stream<SignalMsg> get signalStream => _signalController.stream;

  final String url;

  PriceWebSocketService({String? url}) : url = url ?? _defaultUrl() {
    _connect();
  }

  static String _defaultUrl() {
    if (kIsWeb) {
      final base = Uri.base;
      final wsScheme = base.scheme == 'https' ? 'wss' : 'ws';
      final host = base.host.isEmpty ? 'localhost' : base.host;
      return '$wsScheme://$host:8080';
    }
    return 'ws://10.0.2.2:8080'; // Android emulator
    // For real phone, use your PC IP: ws://192.168.1.X:8080
  }

  void _connect() {
    _channel = WebSocketChannel.connect(Uri.parse(url));

    _sub = _channel!.stream.listen((event) {
      try {
        final text = event is String ? event : event.toString();
        final j = jsonDecode(text);

        if (j is! Map<String, dynamic>) return;
        final type = (j['type'] ?? '').toString();

        if (type == 'tick') {
          final symbol = (j['symbol'] ?? '').toString();
          final bid = (j['bid'] as num?)?.toDouble();
          final ask = (j['ask'] as num?)?.toDouble();
          if (symbol.isEmpty || bid == null || ask == null) return;
          final mid = (bid + ask) / 2.0;

          _latest[symbol] = MarketPrice(price: mid, change24h: null);
          _pricesController.add(Map<String, MarketPrice>.unmodifiable(_latest));
        }

        if (type == 'candle') {
          _candleController.add(CandleMsg.fromJson(j));
        }

        if (type == 'signal') {
          _signalController.add(SignalMsg.fromJson(j));
        }
      } catch (_) {}
    }, onError: (_) {}, onDone: () {});
  }

  void dispose() {
    _sub?.cancel();
    _channel?.sink.close();
    _pricesController.close();
    _candleController.close();
    _signalController.close();
  }
}
