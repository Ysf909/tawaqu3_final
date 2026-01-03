import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tawaqu3_final/models/market_model.dart';
import 'package:tawaqu3_final/models/signal_msg.dart';
import 'package:tawaqu3_final/services/price_websocket_service.dart';
import 'package:tawaqu3_final/view/widgets/interactive_candlestick_chart.dart';

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
  late String _symbol;

  PriceWebSocketService? _ws;
  StreamSubscription? _candSub;
  StreamSubscription? _sigSub;
  StreamSubscription? _priceSub;

  List<Candle> _candles = const [];
  SignalMsg? _lastSignal;
  double? _livePrice;

  String _defaultWsUrl() {
    if (widget.wsUrlOverride != null && widget.wsUrlOverride!.trim().isNotEmpty) {
      return widget.wsUrlOverride!.trim();
    }
    return PriceWebSocketService.defaultWsUrl;
  }

  @override
  void initState() {
    super.initState();
    _tf = widget.initialTf;
    _symbol = widget.symbol.trim();
    if (_symbol.endsWith('_')) _symbol = _symbol.substring(0, _symbol.length - 1);

    _ws = PriceWebSocketService(wsUrl: _defaultWsUrl());
    unawaited(_ws!.connect());

    _fetchCandles();

    _candSub = _ws!.candlesStream.listen((_) {
      if (!mounted) return;
      _refreshCandles();
    });

    _sigSub = _ws!.signalsStream.listen((s) {
      if (!mounted) return;
      if (s.symbol.toUpperCase() == _symbol.toUpperCase() &&
          s.tf.toLowerCase() == _tf.toLowerCase()) {
        setState(() => _lastSignal = s);
      }
    });

    _priceSub = _ws!.pricesStream.listen((m) {
      if (!mounted) return;
      final p = m[_symbol.toUpperCase()] ?? _ws!.getPrice(_symbol);
      setState(() => _livePrice = p?.effectiveMid);
    });
  }

  void _refreshCandles() {
    final list = _ws?.candlesFor(_symbol, _tf) ?? const <Candle>[];
    setState(() => _candles = List<Candle>.from(list));
  }

  Future<void> _fetchCandles() async {
    await _ws?.requestCandles(_symbol, _tf, limit: 300);
    if (!mounted) return;
    _refreshCandles();
    setState(() {
      _livePrice = _ws?.getPrice(_symbol)?.effectiveMid;
    });
  }

  @override
  void dispose() {
    _candSub?.cancel();
    _sigSub?.cancel();
    _priceSub?.cancel();
    _ws?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("$_symbol • $_tf"),
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
                  color: (_lastSignal!.side.toUpperCase() == "BUY")
                      ? Colors.green.withOpacity(0.10)
                      : Colors.red.withOpacity(0.10),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.30)),
                ),
                child: Text(
                  "Signal: ${_lastSignal!.side.isEmpty ? '—' : _lastSignal!.side}"
                  "${_lastSignal!.entry != null ? "  • entry ${_lastSignal!.entry!.toStringAsFixed(4)}" : ""}"
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
                  border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
                ),
                child: _candles.isEmpty
                    ? const Center(child: Text("Waiting for candles…"))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: InteractiveCandlestickChart(
                          candles: _candles,
                          livePrice: _livePrice,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
