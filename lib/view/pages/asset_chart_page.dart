import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tawaqu3_final/models/market_model.dart';
class AssetChartView extends StatefulWidget {
  final String symbol;
  final String initialTf; // "1m" or "5m"
  final List<Candle> candles;
  final SignalMsg? signal;

  const AssetChartView({
    super.key,
    required this.symbol,
    required this.initialTf,
    required this.candles,
    this.signal,
  });

  @override
  State<AssetChartView> createState() => _AssetChartViewState();
}

class _AssetChartViewState extends State<AssetChartView> {
  late String tf;

  @override
  void initState() {
    super.initState();
    tf = widget.initialTf;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.symbol} • $tf"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => tf = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: "1m", child: Text("1m")),
              PopupMenuItem(value: "5m", child: Text("5m")),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (widget.signal != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: (widget.signal!.side == "BUY")
                      ? Colors.green.withOpacity(0.12)
                      : Colors.red.withOpacity(0.12),
                ),
                child: Text(
                  "Signal: ${widget.signal!.side}"
                  "${widget.signal!.entry != null ? "  • entry ${widget.signal!.entry}" : ""}"
                  "${widget.signal!.score != null ? "  • score ${widget.signal!.score!.toStringAsFixed(2)}" : ""}"
                  "${(widget.signal!.note ?? "").isNotEmpty ? "\n${widget.signal!.note}" : ""}",
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
                  painter: _CandlePainter(widget.candles),
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

      // wick
      canvas.drawLine(Offset(x, y(c.high)), Offset(x, y(c.low)), wickPaint);

      // body
      final top = y(max(c.open, c.close));
      final bottom = y(min(c.open, c.close));
      final rect = Rect.fromLTWH(x - candleW * 0.28, top, candleW * 0.56, max(1.5, bottom - top));
      canvas.drawRect(rect, bodyPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CandlePainter oldDelegate) =>
      oldDelegate.candles != candles;
}
