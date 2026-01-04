import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tawaqu3_final/models/market_model.dart';

class InteractiveCandlestickChart extends StatefulWidget {
  final List<Candle> candles;
  final double? livePrice;
  final int visibleCount;

  const InteractiveCandlestickChart({
    super.key,
    required this.candles,
    required this.livePrice,
    this.visibleCount = 120,
  });

  @override
  State<InteractiveCandlestickChart> createState() =>
      _InteractiveCandlestickChartState();
}

class _InteractiveCandlestickChartState extends State<InteractiveCandlestickChart> {
  int? _selectedIndex; // index inside visible candles

  List<Candle> get _visible {
    final all = widget.candles;
    if (all.isEmpty) return const [];
    if (all.length <= widget.visibleCount) return all;
    return all.sublist(all.length - widget.visibleCount);
  }

  void _setSelectionFromDx(double dx, double width) {
    final vis = _visible;
    if (vis.isEmpty) return;
    final w = width / vis.length;
    final idx = (dx / w).floor().clamp(0, vis.length - 1);
    setState(() => _selectedIndex = idx);
  }

  void _clearSelection() {
    if (_selectedIndex == null) return;
    setState(() => _selectedIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vis = _visible;
    final sel = (_selectedIndex != null && _selectedIndex! >= 0 && _selectedIndex! < vis.length)
        ? vis[_selectedIndex!]
        : null;

    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth;
        final height = c.maxHeight;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPressStart: (d) => _setSelectionFromDx(d.localPosition.dx, width),
          onLongPressMoveUpdate: (d) => _setSelectionFromDx(d.localPosition.dx, width),
          onLongPressEnd: (_) => _clearSelection(),
          child: Stack(
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: _CandlePainter(
                  candles: vis,
                  livePrice: widget.livePrice,
                  selectedIndex: _selectedIndex,
                  theme: theme,
                ),
              ),

              // Live price label (top-right)
              if (widget.livePrice != null)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.surface.withOpacity(0.9),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
                    ),
                    child: Text(
                      'Live: ${widget.livePrice!.toStringAsFixed(4)}',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

              // OHLCV tooltip (long-press)
              if (sel != null)
                Positioned(
                  left: 10,
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: theme.colorScheme.surface.withOpacity(0.92),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 14,
                          spreadRadius: 0,
                          offset: const Offset(0, 6),
                          color: Colors.black.withOpacity(0.10),
                        ),
                      ],
                    ),
                    child: DefaultTextStyle(
                      style: theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time: ${sel.time.toLocal().toIso8601String().replaceFirst("T", " ").split(".").first}',
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              _kv('O', sel.open),
                              _kv('H', sel.high),
                              _kv('L', sel.low),
                              _kv('C', sel.close),
                              _kv('V', sel.volume),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _kv(String k, double v) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$k: ', style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(v.toStringAsFixed(4)),
      ],
    );
  }
}

class _CandlePainter extends CustomPainter {
  final List<Candle> candles;
  final double? livePrice;
  final int? selectedIndex;
  final ThemeData theme;

  _CandlePainter({
    required this.candles,
    required this.livePrice,
    required this.selectedIndex,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    double minP = candles.first.low;
    double maxP = candles.first.high;

    for (final c in candles) {
      if (c.low < minP) minP = c.low;
      if (c.high > maxP) maxP = c.high;
    }

    if (livePrice != null) {
      minP = math.min(minP, livePrice!);
      maxP = math.max(maxP, livePrice!);
    }

    final range = (maxP - minP).abs();
    final pad = range <= 1e-9 ? 1.0 : range * 0.06;
    minP -= pad;
    maxP += pad;

    double y(double p) =>
        size.height - ((p - minP) / (maxP - minP)) * size.height;

    final gridPaint = Paint()
      ..color = theme.colorScheme.onSurface.withOpacity(0.08)
      ..strokeWidth = 1.0;

    // grid (4 horizontal)
    for (int i = 1; i <= 4; i++) {
      final yy = size.height * (i / 5.0);
      canvas.drawLine(Offset(0, yy), Offset(size.width, yy), gridPaint);
    }

    final candleW = size.width / candles.length;
    final wickPaint = Paint()..strokeWidth = 1.2;

    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final x = i * candleW + candleW * 0.5;
      final isUp = c.close >= c.open;

      final bodyColor = isUp ? Colors.green : Colors.red;
      final bodyPaint = Paint()..color = bodyColor;
      wickPaint.color = bodyColor;

      // wick
      canvas.drawLine(Offset(x, y(c.high)), Offset(x, y(c.low)), wickPaint);

      // body
      final top = y(isUp ? c.close : c.open);
      final bot = y(isUp ? c.open : c.close);
      final rect = Rect.fromLTRB(
        x - candleW * 0.28,
        top,
        x + candleW * 0.28,
        bot,
      );
      canvas.drawRect(rect, bodyPaint);
    }

    // live price line
    if (livePrice != null) {
      final p = Paint()
        ..color = theme.colorScheme.primary.withOpacity(0.55)
        ..strokeWidth = 1.4;
      final yy = y(livePrice!);
      canvas.drawLine(Offset(0, yy), Offset(size.width, yy), p);
    }

    // selection crosshair
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < candles.length) {
      final idx = selectedIndex!;
      final c = candles[idx];
      final crossPaint = Paint()
        ..color = theme.colorScheme.onSurface.withOpacity(0.28)
        ..strokeWidth = 1.0;

      final x = idx * candleW + candleW * 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), crossPaint);

      final yy = y(c.close);
      canvas.drawLine(Offset(0, yy), Offset(size.width, yy), crossPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CandlePainter oldDelegate) =>
      oldDelegate.candles != candles ||
      oldDelegate.livePrice != livePrice ||
      oldDelegate.selectedIndex != selectedIndex;
}
