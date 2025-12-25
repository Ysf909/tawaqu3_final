import 'dart:async';
import 'dart:convert';

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

  PriceWebSocketService({
    this.wsUrl = 'ws://127.0.0.1:8080',
  }) {
    _connect();
  }

  void _connect() {
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _sub = _channel!.stream.listen(
      (data) {
        try {
          final m = jsonDecode(data as String) as Map<String, dynamic>;
          final type = (m['type'] ?? '').toString();

          if (type == 'tick') {
            final symbol = (m['symbol'] ?? '').toString();
            final mid = (m['mid'] as num?)?.toDouble()
                ?? (((m['bid'] as num).toDouble() + (m['ask'] as num).toDouble()) / 2.0);

            _latestPrices = Map<String, MarketPrice>.from(_latestPrices);
            _latestPrices[symbol] = MarketPrice(price: mid, change24h: _latestPrices[symbol]?.change24h);
            _pricesCtrl.add(_latestPrices);
          }

          if (type == 'ohlc') {
            final symbol = (m['symbol'] ?? '').toString();
            final tf = (m['tf'] ?? '').toString();
            final list = (m['candles'] as List).cast<Map<String, dynamic>>();
            final candles = list.map((e) => Candle.fromJson(e)).toList(growable: false);
            final key = "${symbol}__${tf}";

            _latestCandles = Map<String, List<Candle>>.from(_latestCandles);
            _latestCandles[key] = candles;
            _candlesCtrl.add(_latestCandles);
          }

          if (type == 'signal') {
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
