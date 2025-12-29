import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tawaqu3_final/models/market_model.dart';
import 'package:tawaqu3_final/services/price_websocket_service.dart' hide SignalMsg;

class AssetChartView extends StatefulWidget {
  final String symbol;
  final String initialTf; // e.g. "15m", "1h", "1d"
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
  static const List<String> _timeframes = [
    '15m',
    '30m',
    '1h',
    '4h',
    '1d',
    '1w',
  ];
  late String _tf;
  PriceWebSocketService? _ws;
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
    _tf = _timeframes.contains(widget.initialTf)
        ? widget.initialTf
        : _timeframes.first;
    _ws = PriceWebSocketService(wsUrl: widget.wsUrlOverride ?? _defaultWsUrl());

    _ws!.candlesStream.listen((m) {
      final sym1 = widget.symbol.toUpperCase();
      final sym2 = sym1.endsWith('_')
          ? sym1.substring(0, sym1.length - 1)
          : sym1;
      final key1 = "${sym1}__${_tf}";
      final key2 = "${sym2}__${_tf}";
      final list = (m[key1] ?? m[key2]) ?? const <Candle>[];
      if (!mounted) return;
      setState(() => _candles = list);
    });

    _ws!.signalStream.listen((s) {
      final sym1 = widget.symbol.toUpperCase();
      final sym2 = sym1.endsWith('_')
          ? sym1.substring(0, sym1.length - 1)
          : sym1;
      if ((s.symbol.toUpperCase() == sym1 || s.symbol.toUpperCase() == sym2) &&
          s.tf == _tf) {
        if (!mounted) return;
        setState(() => _lastSignal = s);
      }
    });
  }

  @override
  void dispose() {
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
              _ws?.setActiveView(symbol: widget.symbol, tf: _tf, limit: 600);
            },
            itemBuilder: (_) => _timeframes
                .map((t) => PopupMenuItem(value: t, child: Text(t)))
                .toList(),
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
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final w = math.max(
                            constraints.maxWidth,
                            _candles.length * 6.0,
                          );
                          return InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            constrained: false,
                            child: SizedBox(
                              width: w,
                              height: constraints.maxHeight,
                              child: CustomPaint(
                                painter: _CandlePainter(_candles),
                              ),
                            ),
                          );
                        },
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
    final visible = candles.length > 120
        ? candles.sublist(candles.length - 120)
        : candles;

    double minP = visible.first.low;
    double maxP = visible.first.high;
    for (final c in visible) {
      if (c.low < minP) minP = c.low;
      if (c.high > maxP) maxP = c.high;
    }
    if ((maxP - minP).abs() < 1e-9) return;

    double y(double p) =>
        size.height - ((p - minP) / (maxP - minP)) * size.height;

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
