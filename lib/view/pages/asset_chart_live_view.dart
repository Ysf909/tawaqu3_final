import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tawaqu3_final/models/market_model.dart';
import 'package:tawaqu3_final/services/price_websocket_service.dart';

class AssetChartLiveView extends StatefulWidget {
  final String symbol;
  final String initialTf; // "1m" or "5m"
  const AssetChartLiveView({super.key, required this.symbol, this.initialTf = "1m"});

  @override
  State<AssetChartLiveView> createState() => _AssetChartLiveViewState();
}

class _AssetChartLiveViewState extends State<AssetChartLiveView> {
  late String tf;
  late final PriceWebSocketService _ws;
  StreamSubscription? _candSub;
  StreamSubscription? _sigSub;

  List<Candle> _candles = const [];
  SignalMsg? _signal;

  @override
  void initState() {
    super.initState();
    tf = widget.initialTf;
    _ws = PriceWebSocketService();

    // 1) fetch stored candles from server
    _fetchCandles();
    // 2) render whatever is currently cached
    _refreshCandles();

    _candSub = _ws.candlesStream.listen((_) {
      if (!mounted) return;
      _refreshCandles();
    });

    _sigSub = _ws.signalsStream.listen((s) {
      if (!mounted) return;
      if (s.symbol.toUpperCase() == widget.symbol.toUpperCase() ||
          s.symbol.toUpperCase() == (widget.symbol.toUpperCase() + "_")) {
        setState(() => _signal = s);
      }
    });
  }

  void _refreshCandles() {
    final c = _ws.candlesFor(widget.symbol, tf);
    setState(() => _candles = List<Candle>.from(c));
  }

  Future<void> _fetchCandles() async {
    await _ws.requestCandles(widget.symbol, tf, limit: 250);
    if (!mounted) return;
    _refreshCandles();
  }

  @override
  void dispose() {
    _candSub?.cancel();
    _sigSub?.cancel();
    _ws.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.symbol} • $tf"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              setState(() => tf = v);
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
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (_signal != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: (_signal!.side == "BUY")
                      ? Colors.green.withOpacity(0.12)
                      : Colors.red.withOpacity(0.12),
                ),
                child: Text(
                  "Signal: ${_signal!.side}"
                  "${_signal!.entry != null ? "  • entry ${_signal!.entry}" : ""}"
                  "${_signal!.score != null ? "  • score ${_signal!.score!.toStringAsFixed(2)}" : ""}"
                  "${(_signal!.note ?? "").isNotEmpty ? "\n${_signal!.note}" : ""}",
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
                child: CustomPaint(
                  painter: _CandlePainter(_candles),
                ),
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
    if (candles.isEmpty) {
      final tp = TextPainter(
        text: const TextSpan(text: "No candles yet", style: TextStyle(color: Colors.grey)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
      return;
    }

    final visible = candles.length > 80 ? candles.sublist(candles.length - 80) : candles;

    double minP = visible.map((c) => c.low).reduce(min);
    double maxP = visible.map((c) => c.high).reduce(max);
    final pad = (maxP - minP) * 0.05;
    minP -= pad;
    maxP += pad;

    double y(double p) => size.height - ((p - minP) / (maxP - minP)) * size.height;

    final candleW = size.width / visible.length;
    final wickPaint = Paint()..strokeWidth = 1.2;

    for (int i = 0; i < visible.length; i++) {
      final c = visible[i];
      final x = i * candleW + candleW * 0.5;

      final isUp = c.close >= c.open;
      final bodyPaint = Paint()..color = isUp ? Colors.green : Colors.red;
      wickPaint.color = bodyPaint.color;

      canvas.drawLine(Offset(x, y(c.high)), Offset(x, y(c.low)), wickPaint);

      final top = y(max(c.open, c.close));
      final bottom = y(min(c.open, c.close));
      final rect = Rect.fromLTWH(x - candleW * 0.28, top, candleW * 0.56, max(1.5, bottom - top));
      canvas.drawRect(rect, bodyPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CandlePainter oldDelegate) => oldDelegate.candles != candles;
}
