import 'dart:async';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/price_websocket_service.dart';

class AssetChartPage extends StatefulWidget {
  final String initialSymbol;
  final List<String> symbols;

  const AssetChartPage({
    super.key,
    required this.initialSymbol,
    required this.symbols,
  });

  @override
  State<AssetChartPage> createState() => _AssetChartPageState();
}

class _AssetChartPageState extends State<AssetChartPage> {
  late String _symbol;
  String _tf = '1m';

  final List<CandleMsg> _candles = [];
  SignalMsg? _lastSignal;

  PriceWebSocketService? _ws;
  StreamSubscription? _candleSub;
  StreamSubscription? _signalSub;

  @override
  void initState() {
    super.initState();
    _symbol = widget.initialSymbol;

    _ws = PriceWebSocketService();

    _candleSub = _ws!.candleStream.listen((c) {
      if (c.symbol == _symbol && c.tf == _tf) {
        setState(() {
          _candles.add(c);
          if (_candles.length > 300) _candles.removeAt(0);
        });
      }
    });

    _signalSub = _ws!.signalStream.listen((s) {
      if (s.symbol == _symbol && s.tf == _tf) {
        setState(() => _lastSignal = s);
      }
    });

    _loadHistory();
  }

  @override
  void dispose() {
    _candleSub?.cancel();
    _signalSub?.cancel();
    _ws?.dispose();
    super.dispose();
  }

  String _httpBase() {
    if (kIsWeb) {
      final base = Uri.base;
      final host = base.host.isEmpty ? 'localhost' : base.host;
      return '${base.scheme}://$host:8080';
    }
    return 'http://10.0.2.2:8080'; // Android emulator
    // Real phone: http://192.168.1.X:8080
  }

  Future<void> _loadHistory() async {
    setState(() {
      _candles.clear();
      _lastSignal = null;
    });

    final uri = Uri.parse('${_httpBase()}/candles?symbol=$_symbol&tf=$_tf&limit=200');
    final res = await http.get(uri);
    if (res.statusCode != 200) return;

    final List data = jsonDecode(res.body);
    final list = data
        .whereType<Map>()
        .map((m) => CandleMsg.fromJson(m.cast<String, dynamic>()))
        .toList();

    setState(() {
      _candles.addAll(list);
    });
  }

  @override
  Widget build(BuildContext context) {
    final closes = _candles.map((c) => c.close).toList();
    final spots = <FlSpot>[];
    for (int i = 0; i < closes.length; i++) {
      spots.add(FlSpot(i.toDouble(), closes[i]));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chart: $_symbol ($_tf)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                DropdownButton<String>(
                  value: _symbol,
                  items: widget.symbols.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _symbol = v);
                    await _loadHistory();
                  },
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _tf,
                  items: const [
                    DropdownMenuItem(value: '1m', child: Text('1m')),
                    DropdownMenuItem(value: '5m', child: Text('5m')),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _tf = v);
                    await _loadHistory();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Model analysis (same candle close time)
            if (_lastSignal != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Text(
                  'SMC Model Output: ${jsonEncode(_lastSignal!.output)}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            const SizedBox(height: 12),

            Expanded(
              child: (_candles.length < 5)
                  ? const Center(child: Text('Waiting for candles…'))
                  : LineChart(
                      LineChartData(
                        titlesData: const FlTitlesData(show: false),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
