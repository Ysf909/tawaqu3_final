import 'dart:async';
import 'dart:convert';
import 'package:tawaqu3_final/models/market_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Mt5TickWebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  final _controller = StreamController<Map<String, MarketPrice>>.broadcast();
  Stream<Map<String, MarketPrice>> get pricesStream => _controller.stream;

  final String wsUrl;

  Mt5TickWebSocketService({required this.wsUrl}) {
    _connect();
  }

  void _connect() {
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    print('WS connecting to: ' + wsUrl);

    _sub = _channel!.stream.listen(
      (msg) {
        print('WS RAW: ' + (msg is String ? msg : msg.toString()));
      final str = msg is String ? msg : msg.toString();

      try {
        final data = jsonDecode(str);

        // Node sends: { type:"tick", symbol:"XAUUSD_", bid:..., ask:..., time:"..." }
        if (data is Map<String, dynamic> && data['type'] == 'tick') {
          final symbol = (data['symbol'] ?? '').toString().toUpperCase();
          final bid = (data['bid'] as num?)?.toDouble();
          final ask = (data['ask'] as num?)?.toDouble();
          if (symbol.isEmpty || bid == null || ask == null) return;

          final mid = (bid + ask) / 2.0;

          _controller.add({symbol: MarketPrice(price: mid, change24h: null)});
        }
      } catch (_) {
        // ignore malformed
      }
    });
  }

  void dispose() {
    _sub?.cancel();
    _channel?.sink.close();
    _controller.close();
  }
}

