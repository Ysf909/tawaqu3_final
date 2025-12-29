import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tawaqu3_final/models/market_model.dart' show Candle;
import 'package:tawaqu3_final/models/trade_entity.dart';
import 'package:tawaqu3_final/models/trade_models.dart' hide TradeEntity;
import 'package:tawaqu3_final/repository/history_repository.dart';
import 'package:tawaqu3_final/repository/trade_repository.dart';
import 'package:tawaqu3_final/services/ict_ort_service.dart';
import 'package:tawaqu3_final/services/price_websocket_service.dart';

class TradePrediction {
  final String pair;
  final double entry;
  final double sl;
  final double tp;
  final double lot;
  final double confidence; // 0..100
  final String side; // BUY/SELL/NONE (derived from model output)

  TradePrediction({
    required this.pair,
    required this.entry,
    required this.sl,
    required this.tp,
    required this.lot,
    required this.confidence,
    required this.side,
  });
}

class TradeViewModel extends ChangeNotifier {
  final HistoryRepository _historyRepo = HistoryRepository();
  final TradeRepository _tradeRepo = TradeRepository();
  final SupabaseClient _client = Supabase.instance.client;

  // Candle/tick stream (from local bridge server)
  late final PriceWebSocketService _ws;

  TradeEntity? _lastTrade;
  TradeEntity? get lastTrade => _lastTrade;

  // UI state
  bool loading = false;
  String? lastError;

  TradePrediction? lastPrediction;

  // â”€â”€ selection (pair / timeframe / type) â”€â”€
  static const List<String> supportedPairs = ['XAUUSD', 'XAGUSD'];

  String _pair = 'XAUUSD';
  String get pair => _pair;
  set pair(String v) {
    _pair = v.toUpperCase();
    notifyListeners();
  }

  String _tf = '1m'; // "1m" or "5m"
  String get tf => _tf;
  set tf(String v) {
    _tf = v.toLowerCase();
    notifyListeners();
  }

  // trading type / model (auto-selected)
  List<TradingType> get allTypes => TradingType.values;
  TradingType _selectedType = TradingType.long;
  TradingType get selectedType => _selectedType;
  set selectedType(TradingType v) {
    _selectedType = v;

    // sensible default TF per style (you can still override in the UI)
    if (v == TradingType.scalper) {
      _tf = '1m';
    } else {
      _tf = '5m';
    }

    notifyListeners();
  }

  TradingModel get selectedModel => modelForType(_selectedType);

  // risk inputs
  double _margin = 1000;
  double get margin => _margin;
  set margin(double v) {
    _margin = v;
    notifyListeners();
  }

  double _riskPercent = 2;
  double get riskPercent => _riskPercent;
  set riskPercent(double v) {
    _riskPercent = v;
    notifyListeners();
  }

  double get calculatedLot {
    final spec = specForPair(_pair);
    const stopLossPips = 30.0; // business rule for lot sizing
    final riskMoney = _margin * (_riskPercent / 100);
    final lot = riskMoney / (spec.pipValuePerLot * stopLossPips);
    return double.parse(lot.toStringAsFixed(2));
  }

  // ORT init
  bool _ortReady = false;
  String _defaultWsUrl() {
    // Web/Desktop: local bridge on this machine
    if (kIsWeb) return 'ws://127.0.0.1:8080';

    // Android emulator can't access PC localhost, use 10.0.2.2
    // Real device: change to your PC IP (e.g. ws://192.168.1.10:8080)
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ws://10.0.2.2:8080';
      case TargetPlatform.iOS:
        return 'ws://127.0.0.1:8080';
      default:
        return 'ws://127.0.0.1:8080';
    }
  }

  TradeViewModel() {
    _ws = PriceWebSocketService(wsUrl: _defaultWsUrl());
  }

  Future<void> markOutcome(TradeOutcome outcome) async {
    final trade = _lastTrade;
    final prediction = lastPrediction;
    if (trade == null || prediction == null) return;

    loading = true;
    notifyListeners();

    try {
      // 1) Direction: long / scalper = +1, short = -1
      final int direction;
      switch (selectedType) {
        case TradingType.short:
          direction = -1;
          break;
        default:
          direction = 1; // long + scalper
          break;
      }

      // 2) Choose which price was hit
      final double exitPrice = (outcome == TradeOutcome.tpHit)
          ? prediction.tp
          : prediction.sl;

      // raw difference (exit - entry)
      final double rawDiff = exitPrice - prediction.entry;

      // signed diff (positive if profit, negative if loss)
      final double signedDiff = direction * rawDiff;

      // 3) Get instrument spec (pipSize, pipValuePerLot)
      final spec = specForPair(prediction.pair);

      // number of pips
      final double pips = signedDiff / spec.pipSize;

      // 4) Final profit in USD
      final double profit = pips * spec.pipValuePerLot * prediction.lot;

      // 5) Update trade row with outcome + profit
      final updatedTrade = await _client
          .from('trades')
          .update({'outcome': outcome.dbValue, 'profit': profit})
          .eq('id', trade.id)
          .select()
          .single();

      _lastTrade = TradeEntity.fromMap(updatedTrade);

      // 6) If you REALLY want to keep users.profit, you can still use RPC:
      await _client.rpc(
        'increment_user_profit',
        params: {'p_user_id': trade.userId, 'p_delta': profit},
      );

      // 7) Also write a snapshot into history with final outcome (optional but nice)
      await _historyRepo.insertHistoryForTrade(
        tradeId: trade.id,
        previousEntry: prediction.entry,
        previousSl: prediction.sl,
        previousTp: prediction.tp,
        previousLot: prediction.lot,
        dateSaved: DateTime.now(),
        outcome: outcome,
      );
    } catch (e, st) {
      debugPrint('markOutcome error: $e\n$st');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> generate() async {
    lastError = null;
    loading = true;
    notifyListeners();

    try {
      final authUser = _client.auth.currentUser;
      if (authUser == null) {
        throw Exception('User not logged in');
      }
      final String userId = authUser.id;

      // 1) Ensure ORT sessions loaded
      if (!_ortReady) {
        await IctOrtService.instance.init();
        _ortReady = true;
      }

      // 2) Fetch candles (if your server is streaming them)
      final candles = _ws.candlesFor(_pair, _tf);

      // If you donâ€™t have candles yet, we canâ€™t build a proper sequence.
      // You can still generate a trade, but it will be low quality.
      if (candles.isEmpty) {
        throw Exception(
          'No candle data received for $_pair ($_tf).\n'
          'Make sure your bridge server / MT5 EA is sending candle updates.',
        );
      }

      // 3) Build model input
      const seqLen = 256; // keep aligned with your training window
      final input = _buildFeatures(candles, seqLen: seqLen);
      final shape = <int>[1, seqLen, 7];

      // 4) Run the model
      final Object? rawOut = (_tf == '1m')
          ? await IctOrtService.instance.predict1m(input, shape)
          : await IctOrtService.instance.predict5m(input, shape);

      final out = _flattenToDoubles(rawOut);
      if (out.isEmpty) {
        throw Exception('Model returned empty output');
      }

      final (side, conf01) = _decodeSideAndConfidence(out);
      final confPct = (conf01 * 100).clamp(0, 100).toDouble();

      // 5) Convert model output â†’ entry / SL / TP
      final lastClose = candles.last.close;
      final spec = specForPair(_pair);

      const stopLossPips = 30.0;
      const takeProfitPips = 60.0;

      final double entry = lastClose;

      final bool isSell = (side == 'SELL');
      final double sl = isSell
          ? entry + stopLossPips * spec.pipSize
          : entry - stopLossPips * spec.pipSize;

      final double tp = isSell
          ? entry - takeProfitPips * spec.pipSize
          : entry + takeProfitPips * spec.pipSize;

      final lot = calculatedLot;

      final prediction = TradePrediction(
        pair: _pair,
        entry: entry,
        sl: sl,
        tp: tp,
        lot: lot,
        confidence: confPct,
        side: side,
      );

      lastPrediction = prediction;

      // 6) Store into Supabase trades
      final trade = await _tradeRepo.insertTrade(
        userId: userId,
        entry: prediction.entry,
        sl: prediction.sl,
        tp: prediction.tp,
        lot: prediction.lot,
        school: selectedModel.label,
        time: DateTime.now(),
      );
      _lastTrade = trade;

      // 7) Initial history snapshot (optional but helpful)
      await _historyRepo.insertHistoryForTrade(
        tradeId: trade.id,
        previousEntry: prediction.entry,
        previousSl: prediction.sl,
        previousTp: prediction.tp,
        previousLot: prediction.lot,
        dateSaved: DateTime.now(),
      );
    } catch (e, st) {
      debugPrint('generate() error: $e\n$st');
      lastError = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Build a [1, seqLen, 7] feature tensor from candles.
  /// We use *relative* features so the model is less sensitive to absolute price levels.
  Float32List _buildFeatures(List<Candle> candles, {required int seqLen}) {
    // use last seqLen candles; pad if needed
    final List<Candle> seq;
    if (candles.length >= seqLen) {
      seq = candles.sublist(candles.length - seqLen);
    } else {
      final pad = List<Candle>.filled(
        seqLen - candles.length,
        candles.first,
        growable: true,
      );
      seq = [...pad, ...candles];
    }

    final double ref = seq.last.close == 0 ? 1.0 : seq.last.close;

    final out = Float32List(seqLen * 7);
    for (int i = 0; i < seqLen; i++) {
      final c = seq[i];

      final o = c.open / ref - 1.0;
      final h = c.high / ref - 1.0;
      final l = c.low / ref - 1.0;
      final cl = c.close / ref - 1.0;

      final body = (c.close - c.open) / ref;
      final range = (c.high - c.low) / ref;

      final vol = (log(1 + max(0.0, c.volume)) / 10.0);

      final base = i * 7;
      out[base + 0] = o.toDouble();
      out[base + 1] = h.toDouble();
      out[base + 2] = l.toDouble();
      out[base + 3] = cl.toDouble();
      out[base + 4] = body.toDouble();
      out[base + 5] = range.toDouble();
      out[base + 6] = vol.toDouble();
    }

    return out;
  }

  (String side, double confidence01) _decodeSideAndConfidence(
    List<double> out,
  ) {
    // Heuristics that work for common model heads:
    // - 3 logits/probs => [SELL, NONE, BUY]
    // - 2 logits/probs => [SELL, BUY]
    // - 1 logit        => sign-based BUY/SELL
    if (out.length >= 3) {
      final probs = _softmax(out.take(3).toList());
      final maxIdx = probs.indexWhere((p) => p == probs.reduce(max));
      final side = (maxIdx == 0)
          ? 'SELL'
          : (maxIdx == 2)
          ? 'BUY'
          : 'NONE';
      return (side, probs[maxIdx]);
    }

    if (out.length == 2) {
      final probs = _softmax(out);
      final side = (probs[0] >= probs[1]) ? 'SELL' : 'BUY';
      return (side, max(probs[0], probs[1]));
    }

    final pBuy = _sigmoid(out.first);
    final side = (pBuy >= 0.5) ? 'BUY' : 'SELL';
    final conf = (pBuy - 0.5).abs() * 2.0; // 0..1
    return (side, conf);
  }

  List<double> _softmax(List<double> logits) {
    final mx = logits.reduce(max);
    final exps = logits.map((x) => exp(x - mx)).toList(growable: false);
    final s = exps.fold<double>(0, (a, b) => a + b);
    return exps.map((e) => e / (s == 0 ? 1.0 : s)).toList(growable: false);
  }

  double _sigmoid(double x) => 1.0 / (1.0 + exp(-x));

  List<double> _flattenToDoubles(Object? v) {
    if (v == null) return const [];
    if (v is Float32List)
      return v.map((e) => e.toDouble()).toList(growable: false);
    if (v is Float64List) return v.toList(growable: false);
    if (v is Int64List)
      return v.map((e) => e.toDouble()).toList(growable: false);
    if (v is List) {
      final out = <double>[];
      for (final item in v) {
        out.addAll(_flattenToDoubles(item));
      }
      return out;
    }
    if (v is num) return [v.toDouble()];
    return const [];
  }

  @override
  void dispose() {
    _ws.dispose();
    IctOrtService.instance.dispose();
    super.dispose();
  }
}
