import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tawaqu3_final/models/market_model.dart';

/// A lightweight TradingView-ish candle chart:
/// - Drag left/right to pan through history
/// - Pinch (or mouse wheel) to zoom
/// - Long-press to show crosshair + OHLC tooltip
class InteractiveCandlestickChart extends StatefulWidget {
  final String? symbol; // used only for formatting
  final List<Candle> candles;
  final double? livePrice;

  const InteractiveCandlestickChart({
    super.key,
    required this.candles,
    this.livePrice,
    this.symbol,
  });

  @override
  State<InteractiveCandlestickChart> createState() => _InteractiveCandlestickChartState();
}

class _InteractiveCandlestickChartState extends State<InteractiveCandlestickChart> {
  double _zoom = 1.0; // 0.6 .. 3.0
  int _offsetFromEnd = 0; // 0 = latest at right edge

  int? _selectedIndexGlobal;
  Offset? _crosshairLocal;

  double _zoomStart = 1.0;
  int _offsetStart = 0;

  static const double _baseCandleW = 7.5;
  static const double _gap = 2.0;

  int _decimalsForSymbol(String? sym) {
    final s = (sym ?? '').toUpperCase();
    if (s.contains('JPY')) return 3;
    if (s.contains('XAU') || s.contains('XAG')) return 2;
    if (s.contains('BTC') || s.contains('ETH')) return 2;
    return 5; // EURUSD etc.
  }

  double _stepPx() => (_baseCandleW * _zoom) + _gap;

  int _visibleCount(double width, int total) {
    final v = (width / _stepPx()).floor();
    return v.clamp(25, total);
  }

  int _maxOffset(int total, int visible) => math.max(0, total - visible);

  void _clampOffset(double width) {
    final total = widget.candles.length;
    if (total == 0) return;
    final visible = _visibleCount(width, total);
    final maxOff = _maxOffset(total, visible);
    _offsetFromEnd = _offsetFromEnd.clamp(0, maxOff);
  }

  void _resetView() {
    setState(() {
      _zoom = 1.0;
      _offsetFromEnd = 0;
      _selectedIndexGlobal = null;
      _crosshairLocal = null;
    });
  }

  void _selectAt(Offset local, Size size) {
    final total = widget.candles.length;
    if (total == 0) return;

    final visible = _visibleCount(size.width, total);
    final maxOff = _maxOffset(total, visible);
    _offsetFromEnd = _offsetFromEnd.clamp(0, maxOff);

    final start = math.max(0, total - visible - _offsetFromEnd);
    final idxInWindow = (local.dx / _stepPx()).floor().clamp(0, visible - 1);
    final global = (start + idxInWindow).clamp(0, total - 1);

    setState(() {
      _selectedIndexGlobal = global;
      _crosshairLocal = local;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        _clampOffset(c.maxWidth);

        return Listener(
          onPointerSignal: (sig) {
            if (sig is PointerScrollEvent && kIsWeb) {
              // Mouse wheel zoom (web)
              final delta = (-sig.scrollDelta.dy / 450.0);
              final next = (_zoom * (1.0 + delta)).clamp(0.6, 3.0);
              setState(() => _zoom = next);
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: _resetView,

            // Pinch zoom + pan
            onScaleStart: (d) {
              _zoomStart = _zoom;
              _offsetStart = _offsetFromEnd;
            },
            onScaleUpdate: (d) {
              final total = widget.candles.length;
              if (total == 0) return;

              final nextZoom = (_zoomStart * d.scale).clamp(0.6, 3.0);
              final step = (_baseCandleW * nextZoom) + _gap;

              final visible = (c.maxWidth / step).floor().clamp(25, total);
              final maxOff = _maxOffset(total, visible);

              final panCandles = (-d.focalPointDelta.dx / step).round();

              setState(() {
                _zoom = nextZoom;
                _offsetFromEnd = (_offsetStart + panCandles).clamp(0, maxOff);
              });
            },

            // Drag pan
            onHorizontalDragUpdate: (d) {
              final total = widget.candles.length;
              if (total == 0) return;

              final step = _stepPx();
              final deltaCandles = (d.delta.dx / step).round(); // right drag => newer
              if (deltaCandles == 0) return;

              final visible = _visibleCount(c.maxWidth, total);
              final maxOff = _maxOffset(total, visible);

              setState(() {
                _offsetFromEnd = (_offsetFromEnd - deltaCandles).clamp(0, maxOff);
              });
            },

            // Crosshair
            onLongPressStart: (d) => _selectAt(d.localPosition, Size(c.maxWidth, c.maxHeight)),
            onLongPressMoveUpdate: (d) => _selectAt(d.localPosition, Size(c.maxWidth, c.maxHeight)),
            onLongPressEnd: (_) => setState(() {
              _selectedIndexGlobal = null;
              _crosshairLocal = null;
            }),

            child: CustomPaint(
              painter: _KlinePainter(
                candles: widget.candles,
                livePrice: widget.livePrice,
                zoom: _zoom,
                offsetFromEnd: _offsetFromEnd,
                selectedIndexGlobal: _selectedIndexGlobal,
                crosshairLocal: _crosshairLocal,
                decimals: _decimalsForSymbol(widget.symbol),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}

class _KlinePainter extends CustomPainter {
  final List<Candle> candles;
  final double? livePrice;

  final double zoom;
  final int offsetFromEnd;

  final int? selectedIndexGlobal;
  final Offset? crosshairLocal;

  final int decimals;

  static const double _baseCandleW = 7.5;
  static const double _gap = 2.0;
  static const double _volFrac = 0.22;

  _KlinePainter({
    required this.candles,
    required this.livePrice,
    required this.zoom,
    required this.offsetFromEnd,
    required this.selectedIndexGlobal,
    required this.crosshairLocal,
    required this.decimals,
  });

  double _stepPx() => (_baseCandleW * zoom) + _gap;

  int _visibleCount(double width, int total) {
    final v = (width / _stepPx()).floor();
    return v.clamp(25, total);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final step = _stepPx();
    final total = candles.length;
    final visible = _visibleCount(size.width, total);
    final maxOff = math.max(0, total - visible);
    final off = offsetFromEnd.clamp(0, maxOff);

    final start = math.max(0, total - visible - off);
    final end = math.min(total, start + visible);
    final view = candles.sublist(start, end);

    final priceH = size.height * (1.0 - _volFrac);
    final volTop = priceH;
    final volH = size.height - volTop;

    double minP = view.first.low;
    double maxP = view.first.high;
    double maxV = 0.0;

    for (final c in view) {
      if (c.low < minP) minP = c.low;
      if (c.high > maxP) maxP = c.high;
      if (c.volume > maxV) maxV = c.volume;
    }

    final pad = (maxP - minP) * 0.08;
    if (pad > 0) {
      minP -= pad;
      maxP += pad;
    } else {
      minP -= 1;
      maxP += 1;
    }

    double yFor(double p) {
      final t = (p - minP) / (maxP - minP);
      return priceH - (t * (priceH - 8)) - 4;
    }

    final grid = Paint()
      ..color = const Color(0xFF000000).withOpacity(0.06)
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      final y = priceH * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (int i = 1; i <= 4; i++) {
      final x = size.width * (i / 5);
      canvas.drawLine(Offset(x, 0), Offset(x, priceH), grid);
    }
    canvas.drawLine(Offset(0, volTop), Offset(size.width, volTop), grid);

    final upBody = Paint()..color = Colors.green.withOpacity(0.95);
    final downBody = Paint()..color = Colors.red.withOpacity(0.95);
    final upWick = Paint()
      ..color = Colors.green.withOpacity(0.85)
      ..strokeWidth = 1.2;
    final downWick = Paint()
      ..color = Colors.red.withOpacity(0.85)
      ..strokeWidth = 1.2;

    final volUp = Paint()..color = Colors.green.withOpacity(0.25);
    final volDown = Paint()..color = Colors.red.withOpacity(0.25);

    final candleW = (_baseCandleW * zoom).clamp(3.0, 20.0);

    for (int i = 0; i < view.length; i++) {
      final c = view[i];
      final xCenter = (i * step) + (step / 2);

      final isUp = c.close >= c.open;
      final bodyPaint = isUp ? upBody : downBody;
      final wickPaint = isUp ? upWick : downWick;

      final yO = yFor(c.open);
      final yC = yFor(c.close);
      final yH = yFor(c.high);
      final yL = yFor(c.low);

      canvas.drawLine(Offset(xCenter, yH), Offset(xCenter, yL), wickPaint);

      final top = math.min(yO, yC);
      final bottom = math.max(yO, yC);
      final bodyRect = Rect.fromLTWH(xCenter - candleW / 2, top, candleW, math.max(1.5, bottom - top));
      canvas.drawRect(bodyRect, bodyPaint);

      if (maxV > 0 && volH > 4) {
        final vh = (c.volume / maxV) * (volH - 6);
        final vRect = Rect.fromLTWH(xCenter - candleW / 2, (volTop + volH - 3) - vh, candleW, vh);
        canvas.drawRect(vRect, isUp ? volUp : volDown);
      }
    }

    final labelStyle = TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.55));
    for (int i = 0; i <= 4; i++) {
      final t = i / 4;
      final p = maxP - (t * (maxP - minP));
      final y = yFor(p);
      final tp = TextPainter(
        text: TextSpan(text: p.toStringAsFixed(decimals), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - tp.width - 6, y - tp.height / 2));
    }

    final int every = math.max(5, (visible / 4).floor());
    for (int i = 0; i < view.length; i += every) {
      final x = (i * step) + (step / 2);
      final t = view[i].time.toLocal();
      final s = "${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} "
          "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
      final tp = TextPainter(
        text: TextSpan(text: s, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 120);
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - tp.height - 2));
    }

    if (livePrice != null) {
      final y = yFor(livePrice!);
      final lp = Paint()
        ..color = Colors.blue.withOpacity(0.45)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lp);

      final txt = livePrice!.toStringAsFixed(decimals);
      final tp = TextPainter(
        text: TextSpan(
          text: txt,
          style: TextStyle(fontSize: 11, color: Colors.blue.withOpacity(0.85), fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - tp.width - 14, y - tp.height / 2 - 4, tp.width + 10, tp.height + 8),
        const Radius.circular(8),
      );
      canvas.drawRRect(r, Paint()..color = Colors.blue.withOpacity(0.08));
      tp.paint(canvas, Offset(size.width - tp.width - 9, y - tp.height / 2));
    }

    if (selectedIndexGlobal != null && crosshairLocal != null) {
      final global = selectedIndexGlobal!.clamp(0, total - 1);
      if (global >= start && global < end) {
        final idx = global - start;
        final x = (idx * step) + (step / 2);

        final cross = Paint()
          ..color = Colors.black.withOpacity(0.25)
          ..strokeWidth = 1;

        canvas.drawLine(Offset(x, 0), Offset(x, priceH), cross);

        final c = candles[global];
        final y = yFor(c.close);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), cross);

        final hi = Paint()..color = Colors.black.withOpacity(0.05);
        canvas.drawRect(Rect.fromLTWH(x - (step / 2), 0, step, priceH), hi);

        final t = c.time.toLocal();
        final timeStr =
            "${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} "
            "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

        final tip = "O ${c.open.toStringAsFixed(decimals)}  "
            "H ${c.high.toStringAsFixed(decimals)}  "
            "L ${c.low.toStringAsFixed(decimals)}  "
            "C ${c.close.toStringAsFixed(decimals)}\n"
            "V ${c.volume.toStringAsFixed(0)}   $timeStr";

        final tp = TextPainter(
          text: TextSpan(
            text: tip,
            style: TextStyle(fontSize: 12, height: 1.25, color: Colors.black.withOpacity(0.78)),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: size.width * 0.75);

        final box = RRect.fromRectAndRadius(
          Rect.fromLTWH(10, 10, tp.width + 12, tp.height + 10),
          const Radius.circular(12),
        );
        canvas.drawRRect(box, Paint()..color = Colors.white.withOpacity(0.86));
        canvas.drawRRect(
          box,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Colors.black.withOpacity(0.08),
        );
        tp.paint(canvas, const Offset(16, 15));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KlinePainter old) {
    return old.candles != candles ||
        old.livePrice != livePrice ||
        old.zoom != zoom ||
        old.offsetFromEnd != offsetFromEnd ||
        old.selectedIndexGlobal != selectedIndexGlobal ||
        old.crosshairLocal != crosshairLocal ||
        old.decimals != decimals;
  }
}
