import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/market_model.dart';

// Some UI files do:  import '...price_websocket_service.dart' hide SignalMsg;
// That causes an error if SignalMsg is not exported from this library.
export '../models/market_model.dart' show SignalMsg;

class PriceWebSocketService {
  final String wsUrl;

  WebSocket? _ws;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  bool _disposed = false;

  final _tickCtl = StreamController<TickMsg>.broadcast();
  final _sigCtl = StreamController<SignalMsg>.broadcast();
  final _candlesCtl = StreamController<Map<String, List<Candle>>>.broadcast();

  final Map<String, List<Candle>> _candles = {};
  final Map<String, Completer<List<Candle>>> _pending = {};

  Stream<TickMsg> get tickStream => _tickCtl.stream;
  Stream<SignalMsg> get signalStream => _sigCtl.stream;
  Stream<Map<String, List<Candle>>> get candlesStream => _candlesCtl.stream;

  PriceWebSocketService({required this.wsUrl}) {
    _connect();
  }

  String _key(String symbol, String tf) => '${symbol.toUpperCase()}__${tf}';

  Future<void> _connect() async {
    if (_disposed) return;
    try {
      _ws = await WebSocket.connect(wsUrl);
      _sub = _ws!.listen(
        _onMsg,
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _sub?.cancel();
    _sub = null;
    try {
      _ws?.close();
    } catch (_) {}
    _ws = null;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 1), () {
      if (_ws != null || _disposed) return;
      _connect();
    });
  }

  void _emitCandles() {
    // Emit an immutable snapshot so listeners don't mutate internal state
    final snap = <String, List<Candle>>{};
    _candles.forEach((k, v) {
      snap[k] = List<Candle>.unmodifiable(v);
    });
    _candlesCtl.add(Map<String, List<Candle>>.unmodifiable(snap));
  }

  void _onMsg(dynamic data) {
    if (_disposed) return;
    try {
      final j = jsonDecode(data as String) as Map<String, dynamic>;
      final type = (j['type'] ?? '').toString();

      if (type == 'tick') {
        _tickCtl.add(TickMsg.fromJson(j));
        return;
      }

      if (type == 'signal') {
        _sigCtl.add(SignalMsg.fromJson(j));
        return;
      }

      // Streaming single candle
      if (type == 'candle') {
        final symbol = (j['symbol'] ?? '').toString().toUpperCase();
        final tf = (j['tf'] ?? '1m').toString();
        final c = Candle.fromJson(j);
        final k = _key(symbol, tf);

        final list = _candles.putIfAbsent(k, () => <Candle>[]);

        // upsert by time
        final idx = list.indexWhere(
          (x) => x.time.millisecondsSinceEpoch == c.time.millisecondsSinceEpoch,
        );
        if (idx >= 0) {
          list[idx] = c;
        } else {
          list.add(c);
          list.sort((a, b) => a.time.compareTo(b.time));
          if (list.length > 800) list.removeRange(0, list.length - 800);
        }

        _emitCandles();
        return;
      }

      // Snapshot candles list from server
      if (type == 'ohlc' || type == 'candles') {
        final symbol = (j['symbol'] ?? '').toString().toUpperCase();
        final tf = (j['tf'] ?? '1m').toString();
        final k = _key(symbol, tf);

        final raw = (j['candles'] as List?) ?? const [];
        final list =
            raw.map((e) => Candle.fromJson(e as Map<String, dynamic>)).toList()
              ..sort((a, b) => a.time.compareTo(b.time));

        _candles[k] = list;
        _emitCandles();

        // complete pending waiter
        final c = _pending.remove(k);
        if (c != null && !c.isCompleted) {
          c.complete(List<Candle>.from(list));
        }
        return;
      }
    } catch (_) {
      // ignore bad messages
    }
  }

  void requestCandles(String symbol, String tf, {int limit = 400}) {
    final msg = jsonEncode({
      'type': 'get_candles',
      'symbol': symbol.toUpperCase(),
      'tf': tf,
      'limit': limit,
    });
    try {
      _ws?.add(msg);
    } catch (_) {}
  }

  // Used by some UI files: they call setActiveView(symbol: ..., tf: ...)
  void setActiveView({
    required String symbol,
    required String tf,
    int limit = 400,
  }) {
    requestCandles(symbol, tf, limit: limit);
  }

  List<Candle> candlesFor(String symbol, String tf) {
    final k = _key(symbol, tf);
    return List<Candle>.unmodifiable(_candles[k] ?? const []);
  }

  Future<List<Candle>> ensureCandles(
    String symbol,
    String tf, {
    int minCount = 50,
    Duration timeout = const Duration(seconds: 4),
    int limit = 400,
  }) async {
    final k = _key(symbol, tf);
    final current = _candles[k];
    if (current != null && current.length >= minCount) {
      return List<Candle>.from(current);
    }

    // If another caller is already waiting, reuse it
    final existing = _pending[k];
    if (existing != null) {
      try {
        return await existing.future.timeout(timeout);
      } catch (_) {
        return List<Candle>.from(_candles[k] ?? const []);
      }
    }

    final c = Completer<List<Candle>>();
    _pending[k] = c;

    requestCandles(symbol, tf, limit: limit);

    try {
      return await c.future.timeout(timeout);
    } catch (_) {
      // return whatever we have
      return List<Candle>.from(_candles[k] ?? const []);
    } finally {
      _pending.remove(k);
    }
  }

  void dispose() {
    _disposed = true;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _sub?.cancel();
    _sub = null;

    try {
      _ws?.close();
    } catch (_) {}
    _ws = null;

    _tickCtl.close();
    _sigCtl.close();
    _candlesCtl.close();
  }
}
