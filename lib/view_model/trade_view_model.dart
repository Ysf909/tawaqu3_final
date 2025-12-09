import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/trade_models.dart';
import '../models/history_trade.dart';
import '../repository/history_repository.dart';

class TradePrediction {
  final String pair;
  final double entry;
  final double sl;
  final double tp;
  final double lot;
  final double confidence;

  TradePrediction({
    required this.pair,
    required this.entry,
    required this.sl,
    required this.tp,
    required this.lot,
    required this.confidence,
  });
}

class TradeViewModel extends ChangeNotifier {
  final HistoryRepository _historyRepo = HistoryRepository();
  final SupabaseClient _client = Supabase.instance.client;

  TradeViewModel();

  // ── trading type / model (simplified) ──
  List<TradingType> get allTypes => TradingType.values;
  TradingType _selectedType = TradingType.long;
  TradingType get selectedType => _selectedType;
  set selectedType(TradingType v) {
    _selectedType = v;
    notifyListeners();
  }

  TradingModel get selectedModel => modelForType(_selectedType);

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
    const pipValuePerLot = 10.0;
    const stopLossPips = 30.0;
    final riskMoney = _margin * (_riskPercent / 100);
    final lot = riskMoney / (pipValuePerLot * stopLossPips);
    return double.parse(lot.toStringAsFixed(2));
  }

  bool loading = false;
  TradePrediction? lastPrediction;

  Future<void> generate() async {
    loading = true;
    notifyListeners();

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        // not logged in → don’t save / maybe throw or just return
        loading = false;
        notifyListeners();
        return;
      }

      final userId = user.id;
      final lot = calculatedLot;

      // TODO: Plug your real logic (ICT/SMC/Trend)
      final prediction = TradePrediction(
        pair: 'EURUSD',
        entry: 1.1000,
        sl: 1.0970,
        tp: 1.1060,
        lot: lot,
        confidence: 92,
      );

      lastPrediction = prediction;

      final historyTrade = HistoryTrade(
        userId: userId,
        tradeId: _generateTradeId(),
        previousEntry: prediction.entry,
        previousSl: prediction.sl,
        previousTp: prediction.tp,
        previousLot: prediction.lot,
        dateSaved: DateTime.now(),
      );

      await _historyRepo.insertHistoryTrade(historyTrade);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  String _generateTradeId() {
    final rand = Random().nextInt(999999999);
    return 'T$rand';
  }
}
