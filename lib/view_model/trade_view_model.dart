import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tawaqu3_final/models/market_model.dart';
import 'package:tawaqu3_final/models/trade_models.dart';
import 'package:tawaqu3_final/models/trading_labels.dart';
import 'package:tawaqu3_final/repository/trade_repository.dart';
import 'package:tawaqu3_final/services/ict_ort_service.dart';
import 'package:tawaqu3_final/services/price_websocket_service.dart';

class TradeRecommendation {
  final String id; // will become uuid from DB when saved
  final String pair;
  final String side; // BUY / SELL
  final double confidence; // 0-100
  final double entry;
  final double sl;
  final double tp;
  final double lot;

  final TradeOutcome? outcome;
  final double profit; // computed when closed
  final DateTime createdAt;

  const TradeRecommendation({
    required this.id,
    required this.pair,
    required this.side,
    required this.confidence,
    required this.entry,
    required this.sl,
    required this.tp,
    required this.lot,
    required this.createdAt,
    this.outcome,
    this.profit = 0.0,
  });

  TradeRecommendation copyWith({
    String? id,
    TradeOutcome? outcome,
    double? profit,
  }) => TradeRecommendation(
    id: id ?? this.id,
    pair: pair,
    side: side,
    confidence: confidence,
    entry: entry,
    sl: sl,
    tp: tp,
    lot: lot,
    createdAt: createdAt,
    outcome: outcome ?? this.outcome,
    profit: profit ?? this.profit,
  );
}

class TradeViewModel extends ChangeNotifier {
  List<String> allowedTfsForType(TradingType type) {
    switch (type) {
      case TradingType.scalper:
        return const ['1m', '5m'];
      case TradingType.short:
        return const ['15m', '30m'];
      case TradingType.long:
        return const ['1h', '4h', '1d'];
    }
  }

  List<String> get availableTfs => allowedTfsForType(_selectedType);

  bool _isUuid(String s) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(s);

  double _calcProfit(TradeRecommendation t, TradeOutcome outcome) {
    final exitPrice = (outcome == TradeOutcome.tpHit) ? t.tp : t.sl;

    // Use your specForPair() from trade_models.dart
    final spec = specForPair(t.pair);

    // Pips moved in our favor (positive = profit)
    final diff = (t.side.toUpperCase() == 'BUY')
        ? (exitPrice - t.entry)
        : (t.entry - exitPrice);

    final pips = diff / spec.pipSize;
    final profit = pips * spec.pipValuePerLot * t.lot;

    return profit;
  }

  TradeViewModel({PriceWebSocketService? ws, TradeRepository? history})
    : _ws = ws ?? PriceWebSocketService.instance,
      _history = history ?? TradeRepository() {
    unawaited(_ws.connect());
    unawaited(_initIct());
  }

  final PriceWebSocketService _ws;
  final TradeRepository _history;

  final SupabaseClient _client = Supabase.instance.client;

  bool _ictReady = false;

  Future<void> _initIct() async {
    try {
      await IctOrtService.instance.init();
      _ictReady = true;
      notifyListeners();
    } catch (e) {
      _ictReady = false;
      _lastError = 'ICT model init failed: $e';
      notifyListeners();
    }
  }

  static const List<String> supportedPairs = <String>[
    'XAUUSD',
    'XAGUSD',
    'BTCUSD',
    'ETHUSD',
  ];

  String _pair = supportedPairs.first;
  String get pair => _pair;
  set pair(String v) {
    _pair = v;
    notifyListeners();
  }

  String _tf = '5m';
  String get tf => _tf;
  set tf(String v) {
    _tf = v;
    notifyListeners();
  }

  // Trading type toggle (kept for UI flow) — model is locked to ICT for now
  List<TradingType> get allTypes => TradingType.values;

  TradingType _selectedType = TradingType.values.first;
  TradingType get selectedType => _selectedType;
  set selectedType(TradingType v) {
    _selectedType = v;
    final allowed = allowedTfsForType(v);
    if (!allowed.contains(_tf)) _tf = allowed.first;
    notifyListeners();
  }

  // LOCKED
  TradingModel get selectedModel => modelForType(_selectedType);

  double _margin = 1000.0;
  double get margin => _margin;
  set margin(double v) {
    _margin = v;
    notifyListeners();
  }

  double _riskPercent = 1.0;
  double get riskPercent => _riskPercent;
  set riskPercent(double v) {
    _riskPercent = v;
    notifyListeners();
  }

  double get calculatedLot {
    final riskAmount = _margin * (_riskPercent / 100.0);
    final lot = riskAmount / 100.0;
    return lot.clamp(0.01, 50.0);
  }

  bool _loading = false;
  bool get loading => _loading;

  String? _lastError;
  String? get lastError => _lastError;

  TradeRecommendation? _lastPrediction;
  TradeRecommendation? get lastPrediction => _lastPrediction;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void generate() {
    unawaited(_generateAsync());
  }

  Future<void> _generateAsync() async {
    if (_loading) return;
    _lastError = null;
    _setLoading(true);

    try {
      if (!_ictReady) {
        // try init once more
        await _initIct();
      }
      if (!_ictReady) {
        throw Exception('ICT model not ready yet.');
      }

      // candles
      List<Candle> candles = const [];
      try {
        candles = await _ws.requestCandles(
          _pair,
          _tf,
          limit: 600,
          timeout: const Duration(seconds: 6),
        );
      } catch (_) {
        candles = _ws.getCandles(_pair, _tf);
      }

      if (candles.length < 60) {
        _lastPrediction = null;
        _lastError =
            'Not enough candles for $_pair ($_tf). Need at least 60, got ${candles.length}.';
        notifyListeners();
        return;
      }

      final last = candles.last;
      final entry = last.close;

      // -------- ICT inference (uses real candles as features) --------
      final features = _buildFeatures60(candles);
      final out = await _predictWithIct(features, tf: _tf);

      final side = out.side;
      final confidence = out.confidence;

      // SL/TP derived from volatility (ATR) for now (still data-driven, no constants)
      final atr = _atr(candles, 14);
      final slDist = max(atr * 1.5, entry.abs() * 0.0008);
      final tpDist = slDist * 2.0;

      final sl = (side == 'BUY') ? (entry - slDist) : (entry + slDist);
      final tp = (side == 'BUY') ? (entry + tpDist) : (entry - tpDist);

      final rec = TradeRecommendation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        pair: _pair,
        side: side,
        confidence: confidence,
        entry: entry,
        sl: sl,
        tp: tp,
        lot: calculatedLot,
        createdAt: DateTime.now(),
      );

      _lastPrediction = rec;

      // Save to Supabase if user is logged in
      final uid = _client.auth.currentUser?.id;
      if (uid != null) {
        final tradeUuid = await _history.createTrade(
          userId: uid,
          entry: rec.entry,
          sl: rec.sl,
          tp: rec.tp,
          lot: rec.lot,
          school: selectedModel.label,
          time: rec.createdAt,
          pair: rec.pair,
          side: rec.side,
          confidence: rec.confidence,
          tf: '', // 0-100
        );

        // IMPORTANT: keep DB uuid as the recommendation id
        _lastPrediction = rec.copyWith(id: tradeUuid);
      } else {
        _lastPrediction = rec; // local only
      }

      notifyListeners();
    } catch (e) {
      _lastPrediction = null;
      _lastError = 'Generate failed: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markOutcome(TradeOutcome outcome) async {
    final cur = _lastPrediction;
    if (cur == null) return;

    final profit = _calcProfit(cur, outcome);

    // Update UI immediately
    _lastPrediction = cur.copyWith(outcome: outcome, profit: profit);
    notifyListeners();

    // Persist if logged in + trade was saved (uuid)
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    if (!_isUuid(cur.id)) return;

    try {
      await _history.closeTrade(
        tradeId: cur.id,
        outcome: outcome,
        profit: profit,
      );
    } catch (e) {
      _lastError = 'Failed to save outcome: $e';
      notifyListeners();
    }
  }

  // ---------------- helpers ----------------

  List<double> _buildFeatures60(List<Candle> candles) {
    // last 60 candles => 60 * 5 = 300 floats
    final last60 = candles.length > 60
        ? candles.sublist(candles.length - 60)
        : candles;
    final out = <double>[];
    for (final c in last60) {
      out.add(c.open);
      out.add(c.high);
      out.add(c.low);
      out.add(c.close);
      out.add(c.volume);
    }
    // ensure exactly 300
    if (out.length > 300) return out.sublist(out.length - 300);
    while (out.length < 300) out.insertAll(0, [0, 0, 0, 0, 0]);
    return out;
  }

  double _atr(List<Candle> candles, int period) {
    if (candles.length < period + 1) {
      final c = candles.last;
      return (c.high - c.low).abs().clamp(0.00001, double.infinity);
    }
    double sum = 0;
    for (int i = candles.length - period; i < candles.length; i++) {
      final cur = candles[i];
      final prevClose = candles[i - 1].close;
      final tr = max(
        cur.high - cur.low,
        max((cur.high - prevClose).abs(), (cur.low - prevClose).abs()),
      );
      sum += tr;
    }
    return (sum / period).clamp(0.00001, double.infinity);
  }

  Future<_IctOut> _predictWithIct(
    List<double> features, {
    required String tf,
  }) async {
    final service = IctOrtService.instance;

    // ✅ define x (this fixes your error)
    final Float32List x = Float32List.fromList(features);

    final tfNorm = tf.toLowerCase();

    // We only have ICT models for 1m + 5m.
    // Anything else maps to 5m model for now.
    final bool use1m = (tfNorm == '1m');

    final Object? raw = use1m
        ? await service.predict1m(x, const [1, 60, 5])
        : await service.predict5m(x, const [1, 60, 5]);

    final vec = _flattenToDoubles(raw);

    if (vec.isEmpty) {
      throw Exception(
        'ICT model returned empty output (no out/outputs/score). Check predict server response.',
      );
    }

    // Robust interpretation:
    // - if 1 value => sigmoid => buyProb
    // - if 2+ values => softmax(first 2) => [sell,buy]
    double buyProb;
    if (vec.length == 1) {
      buyProb = 1.0 / (1.0 + exp(-vec[0]));
    } else {
      final probs = _softmax(vec.take(2).toList());
      buyProb = (probs.length > 1) ? probs[1] : probs[0];
    }

    buyProb = buyProb.clamp(0.0, 1.0);
    final side = buyProb >= 0.5 ? 'BUY' : 'SELL';
    final confidence = ((side == 'BUY') ? buyProb : (1.0 - buyProb)) * 100.0;

    return _IctOut(side: side, confidence: confidence.clamp(0.0, 100.0));
  }

  List<double> _softmax(List<double> x) {
    if (x.isEmpty) return const [];
    final mx = x.reduce(max);
    final exps = x.map((v) => exp(v - mx)).toList();
    final sumExp = exps.fold<double>(0.0, (a, b) => a + b);
    if (sumExp == 0) return x.map((_) => 0.0).toList();
    return exps.map((e) => e / sumExp).toList();
  }

  List<double> _flattenToDoubles(Object? o) {
    if (o == null) return const [];

    if (o is List) {
      if (o.isEmpty) return const [];
      final first = o.first;
      if (first is List) return _flattenToDoubles(first);
      return o.map((e) => (e as num).toDouble()).toList();
    }

    // Some runtimes return typed lists
    if (o is Float32List) return o.map((e) => e.toDouble()).toList();
    if (o is Float64List) return o.toList();

    return const [];
  }
}

class _IctOut {
  final String side;
  final double confidence;
  _IctOut({required this.side, required this.confidence});
}
