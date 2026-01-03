import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tawaqu3_final/models/market_model.dart';
import 'package:tawaqu3_final/services/price_websocket_service.dart';

class AssetChartLiveView extends StatefulWidget {
  final String symbol;
  final String initialTf; // "1m","5m","15m","1h"
  const AssetChartLiveView({
    super.key,
    required this.symbol,
    required this.initialTf,
  });

  @override
  State<AssetChartLiveView> createState() => _AssetChartLiveViewState();
}

class _AssetChartLiveViewState extends State<AssetChartLiveView> {
  late String _tf;

  late final PriceWebSocketService _ws = PriceWebSocketService.instance;

  StreamSubscription? _candSub;
  StreamSubscription? _priceSub;

  List<Candle> _candles = const [];
  double? _livePrice;

  int? _selIndex; // index in visible window
  Candle? _selCandle;

  @override
  void initState() {
    super.initState();
    _tf = widget.initialTf;

    // Ensure connected (home page connects too, but this keeps chart standalone)
    unawaited(_ws.connect());

    _priceSub = _ws.pricesStream.listen((m) {
      final sym = widget.symbol.toUpperCase();
      final mp = m[sym] ?? m["${sym}_"];
      final p = mp?.effectiveMid;
      if (!mounted) return;
      if (p != null && p > 0) setState(() => _livePrice = p);
    });

    _candSub = _ws.candlesStream.listen((_) {
      if (!mounted) return;
      _refreshCandles();
    });

    _fetchCandles();
  }

  List<Candle> _visible() {
    final list = _ws.candlesFor(widget.symbol, _tf);
    if (list.isEmpty) return const [];
    return list.length > 140 ? list.sublist(list.length - 140) : list;
  }

  void _refreshCandles() {
    final v = _visible();
    setState(() {
      _candles = v;
      if (_selIndex != null && _candles.isNotEmpty) {
        _selIndex = _selIndex!.clamp(0, _candles.length - 1);
        _selCandle = _candles[_selIndex!];
      }
    });
  }

  Future<void> _fetchCandles() async {
    await _ws.requestCandles(widget.symbol, _tf, limit: 600);
    if (!mounted) return;
    _refreshCandles();
  }

  @override
  void dispose() {
    _candSub?.cancel();
    _priceSub?.cancel();
    super.dispose();
  }

  void _setSelection(Offset localPos, double width) {
    if (_candles.isEmpty || width <= 0) return;
    final idx = ((localPos.dx / width) * _candles.length).floor().clamp(0, _candles.length - 1);
    setState(() {
      _selIndex = idx;
      _selCandle = _candles[idx];
    });
  }

  void _clearSelection() {
    setState(() {
      _selIndex = null;
      _selCandle = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final shown = _selCandle ?? (_candles.isNotEmpty ? _candles.last : null);

    String fmt(double v) => v.toStringAsFixed(2);

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
                _selIndex = null;
                _selCandle = null;
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
            // Info header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Live: ",
                        style: theme.textTheme.labelLarge,
                      ),
                      Text(
                        _livePrice == null ? "--" : fmt(_livePrice!),
                        style: theme.textTheme.titleLarge,
                      ),
                      const Spacer(),
                      if (_selCandle != null)
                        const Text("Long-press", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (shown != null)
                    Text(
                      "O ${fmt(shown.open)}   H ${fmt(shown.high)}   L ${fmt(shown.low)}   C ${fmt(shown.close)}   V ${shown.volume.toStringAsFixed(0)}"
                      "\n${shown.time.toLocal()}",
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    Text("Waiting for candles…", style: theme.textTheme.bodySmall),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  return GestureDetector(
                    onLongPressStart: (d) => _setSelection(d.localPosition, c.maxWidth),
                    onLongPressMoveUpdate: (d) => _setSelection(d.localPosition, c.maxWidth),
                    onLongPressEnd: (_) => _clearSelection(),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.25)),
                      ),
                      child: _candles.isEmpty
                          ? const Center(child: Text("Waiting for candles…"))
                          : CustomPaint(
                              painter: _CandlePainter(
                                candles: _candles,
                                selectedIndex: _selIndex,
                                livePrice: _livePrice,
                              ),
                            ),
                    ),
                  );
                },
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
  final int? selectedIndex; // index in candles list
  final double? livePrice;

  _CandlePainter({
    required this.candles,
    required this.selectedIndex,
    required this.livePrice,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final priceH = size.height * 0.80;
    final volH = size.height - priceH;

    double minP = candles.first.low;
    double maxP = candles.first.high;
    double maxV = 0;
    for (final c in candles) {
      minP = min(minP, c.low);
      maxP = max(maxP, c.high);
      maxV = max(maxV, c.volume);
    }
    if ((maxP - minP).abs() < 1e-9) return;

    final pad = (maxP - minP) * 0.05;
    minP -= pad;
    maxP += pad;

    double y(double p) => priceH - ((p - minP) / (maxP - minP)) * priceH;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.18)
      ..strokeWidth = 1;

    // horizontal grid
    for (int i = 1; i <= 4; i++) {
      final yy = priceH * (i / 5);
      canvas.drawLine(Offset(0, yy), Offset(size.width, yy), gridPaint);
    }

    final candleW = size.width / candles.length;
    final wickPaint = Paint()..strokeWidth = 1.2;

    // candles + volume
    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
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

      // volume bars
      if (maxV > 0) {
        final vh = (c.volume / maxV) * (volH * 0.85);
        final vRect = Rect.fromLTRB(
          x - candleW * 0.22,
          priceH + (volH - vh),
          x + candleW * 0.22,
          priceH + volH,
        );
        canvas.drawRect(vRect, Paint()..color = bodyPaint.color.withOpacity(0.35));
      }
    }

    // live price line
    if (livePrice != null && livePrice! > 0) {
      final yy = y(livePrice!);
      final lpPaint = Paint()
        ..color = Colors.blue.withOpacity(0.65)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(0, yy), Offset(size.width, yy), lpPaint);
    }

    // selection vertical line
    if (selectedIndex != null && selectedIndex! >= 0 && selectedIndex! < candles.length) {
      final x = selectedIndex! * candleW + candleW * 0.5;
      final selPaint = Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(x, 0), Offset(x, priceH), selPaint);
    }

    // min/max labels (simple)
    final tpMax = TextPainter(
      text: TextSpan(text: maxP.toStringAsFixed(2), style: const TextStyle(fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
    tpMax.paint(canvas, Offset(size.width - tpMax.width - 6, 6));

    final tpMin = TextPainter(
      text: TextSpan(text: minP.toStringAsFixed(2), style: const TextStyle(fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
    tpMin.paint(canvas, Offset(size.width - tpMin.width - 6, priceH - tpMin.height - 6));
  }

  @override
  bool shouldRepaint(covariant _CandlePainter oldDelegate) => true;
}
