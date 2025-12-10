import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:tawaqu3_final/services/api_service.dart'; // for MarketPrice
import 'dart:async';
import 'dart:convert';

class PriceWebSocketService {
  late final WebSocketChannel _channel;

  final _pricesController =
      StreamController<Map<String, MarketPrice>>.broadcast();

  Stream<Map<String, MarketPrice>> get pricesStream =>
      _pricesController.stream;

  final Map<String, MarketPrice> _latestPrices = {};
  Timer? _throttleTimer;

  PriceWebSocketService() {
    final uri = Uri.parse(
      'wss://stream.binance.com:9443/stream'
      '?streams=btcusdt@miniTicker/ethusdt@miniTicker',
    );

    // ✅ This works on mobile, desktop AND web
    _channel = WebSocketChannel.connect(uri);

    _channel.stream.listen(
      _handleMessage,
      onError: (error) {
        print('WebSocket error: $error');
      },
      onDone: () {
        print('WebSocket closed');
      },
    );
  }

  void _handleMessage(dynamic event) {
    try {
      final jsonMap = json.decode(event as String) as Map<String, dynamic>;
      final streamName = jsonMap['stream'] as String? ?? '';
      final data = jsonMap['data'] as Map<String, dynamic>?;

      if (data == null) return;

      final streamSymbol = streamName.split('@').first.toUpperCase();

      final lastPriceStr = data['c'] as String? ?? '0';
      final changePercentStr = data['P'] as String? ?? '0';

      final lastPrice = double.tryParse(lastPriceStr) ?? 0.0;
      final changePercent = double.tryParse(changePercentStr);

      final displaySymbol = _mapToDisplaySymbol(streamSymbol);

      _latestPrices[displaySymbol] = MarketPrice(
        price: lastPrice,
        change24h: changePercent,
      );

      _scheduleEmit();
    } catch (e) {
      print('WebSocket parse error: $e');
    }
  }

  String _mapToDisplaySymbol(String providerSymbol) {
    switch (providerSymbol) {
      case 'BTCUSDT':
        return 'BTC/USD';
      case 'ETHUSDT':
        return 'ETH/USD';
      default:
        return providerSymbol;
    }
  }

  void _scheduleEmit() {
    if (_throttleTimer == null || !_throttleTimer!.isActive) {
      _throttleTimer = Timer(const Duration(seconds: 1), () {
        _pricesController.add(
          Map<String, MarketPrice>.from(_latestPrices),
        );
      });
    }
  }

  void dispose() {
    _throttleTimer?.cancel();
    _channel.sink.close();
    _pricesController.close();
  }
}
