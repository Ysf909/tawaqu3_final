import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tawaqu3_final/models/trade_entity.dart';
import 'package:tawaqu3_final/repository/trade_repository.dart';
import 'package:tawaqu3_final/models/trade_models.dart' hide TradeEntity;
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
   final TradeRepository _tradeRepo = TradeRepository();
  final SupabaseClient _client = Supabase.instance.client;
  TradeEntity? _lastTrade;
  TradeEntity? get lastTrade => _lastTrade;
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
    final double exitPrice =
        (outcome == TradeOutcome.tpHit) ? prediction.tp : prediction.sl;

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
        .update({
          'outcome': outcome.dbValue,
          'profit': profit,
        })
        .eq('id', trade.id)
        .select()
        .single();

    _lastTrade = TradeEntity.fromMap(updatedTrade);

    // 6) If you REALLY want to keep users.profit, you can still use RPC:
    await _client.rpc(
      'increment_user_profit',
      params: {
        'p_user_id': trade.userId,
        'p_delta': profit,
      },
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
      final authUser = _client.auth.currentUser;
      if (authUser == null) {
        throw Exception('User not logged in');
      }

      // IMPORTANT: This must be the id that exists in your "users" table.
      // If you mirrored auth.users into users(id), then authUser.id is fine.
      final String userId = authUser.id;

      final lot = calculatedLot;

      // your prediction logic (simplified)
      final prediction = TradePrediction(
        pair: 'XAUUSD',
        entry: 4197.58,
        sl: 4187.00,
        tp: 4225.00,
        lot: lot,
        confidence: 90,
      );

      lastPrediction = prediction;

      // 1) Insert into `trades`
      final trade = await _tradeRepo.insertTrade(
        userId: userId,
        entry: prediction.entry,
        sl: prediction.sl,
        tp: prediction.tp,
        lot: prediction.lot,
        school: selectedModel.label, // ICT / SMC / Trend
        time: DateTime.now(),
      );
   _lastTrade = trade;
      // 2) Insert initial history row referencing that trade
     
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
