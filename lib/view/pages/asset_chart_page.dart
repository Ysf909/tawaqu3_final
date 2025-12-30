import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tawaqu3_final/models/market_model.dart';
import 'package:tawaqu3_final/services/price_websocket_service.dart';

class AssetChartView extends StatefulWidget {
  final String symbol;
  final String initialTf; // "1m" or "5m"
  final String? wsUrlOverride;

  const AssetChartView({
    super.key,
    required this.symbol,
    required this.initialTf,
    this.wsUrlOverride,
  });

  @override
  State<AssetChartView> createState() => _AssetChartViewState();
}

class _AssetChartViewState extends State<AssetChartView> {
  late String _tf;
  PriceWebSocketService? _ws;
  StreamSubscription? _candSub;
  StreamSubscription? _sigSub;
  List<Candle> _candles = const [];
  SignalMsg? _lastSignal;

  String _defaultWsUrl() {
    if (kIsWeb) return 'ws://127.0.0.1:8080';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ws://10.0.2.2:8080';
      default:
        return 'ws://127.0.0.1:8080';
    }
  }

  @override
  void initState() {
    super.initState();
    _tf = widget.initialTf;
    _ws = PriceWebSocketService(wsUrl: widget.wsUrlOverride ?? _defaultWsUrl());

    // fetch stored candles from server
    _fetchCandles();

    _candSub = _ws!.candlesStream.listen((_) {
      if (!mounted) return;
      _refreshCandles();
    });

    _sigSub = _ws!.signalsStream.listen((s) {
      if (!mounted) return;
      if (s.symbol.toUpperCase() == widget.symbol.toUpperCase() && s.tf.toLowerCase() == _tf.toLowerCase()) {
        setState(() => _lastSignal = s);
      }
    });
  }

  void _refreshCandles() {
    final list = _ws?.candlesFor(widget.symbol, _tf) ?? const <Candle>[];
    setState(() => _candles = List<Candle>.from(list));
  }

  Future<void> _fetchCandles() async {
    await _ws?.requestCandles(widget.symbol, _tf, limit: 300);
    if (!mounted) return;
    _refreshCandles();
  }

  @override
  void dispose() {
    _candSub?.cancel();
    _sigSub?.cancel();
    _ws?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.symbol} • $_tf"),
        actions: [
          PopupMenuButton<String>(
            initialValue: _tf,
            onSelected: (v) {
              setState(() {
                _tf = v;
                _candles = const [];
                _lastSignal = null;
              });
              _fetchCandles();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: "1m", child: Text("1m")),
              PopupMenuItem(value: "5m", child: Text("5m")),
              PopupMenuItem(value: "15m", child: Text("15m")),
              PopupMenuItem(value: "1h", child: Text("1h")),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            if (_lastSignal != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: (_lastSignal!.side == "BUY")
                      ? Colors.green.withOpacity(0.12)
                      : Colors.red.withOpacity(0.12),
                ),
                child: Text(
                  "Signal: ${_lastSignal!.side}"
                  "${_lastSignal!.entry != null ? "  • entry ${_lastSignal!.entry}" : ""}"
                  "${_lastSignal!.score != null ? "  • score ${_lastSignal!.score!.toStringAsFixed(2)}" : ""}"
                  "${(_lastSignal!.note ?? "").isNotEmpty ? "\n${_lastSignal!.note}" : ""}",
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: _candles.isEmpty
                    ? const Center(child: Text("Waiting for candles…"))
                    : CustomPaint(painter: _CandlePainter(_candles)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandlePainter extends CustomPainter {
  final List<Candle> candles;
  _CandlePainter(this.candles);

  @override
  void paint(Canvas canvas, Size size) {
    final visible = candles.length > 120 ? candles.sublist(candles.length - 120) : candles;

    double minP = visible.first.low;
    double maxP = visible.first.high;
    for (final c in visible) {
      if (c.low < minP) minP = c.low;
      if (c.high > maxP) maxP = c.high;
    }
    if ((maxP - minP).abs() < 1e-9) return;

    double y(double p) => size.height - ((p - minP) / (maxP - minP)) * size.height;

    final candleW = size.width / visible.length;
    final wickPaint = Paint()..strokeWidth = 1.2;

    for (int i = 0; i < visible.length; i++) {
      final c = visible[i];
      final x = i * candleW + candleW * 0.5;
      final isUp = c.close >= c.open;

      final bodyPaint = Paint()..color = isUp ? Colors.green : Colors.red;
      wickPaint.color = bodyPaint.color;

      // wick
      canvas.drawLine(Offset(x, y(c.high)), Offset(x, y(c.low)), wickPaint);

      // body
      final top = y(isUp ? c.close : c.open);
      final bot = y(isUp ? c.open : c.close);
      final rect = Rect.fromLTRB(
        x - candleW * 0.22,
        top,
        x + candleW * 0.22,
        bot,
      );
      canvas.drawRect(rect, bodyPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CandlePainter oldDelegate) => true;
}
