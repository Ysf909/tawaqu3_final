import 'package:flutter/foundation.dart';
import '../models/trade.dart';

class HistoryViewModel extends ChangeNotifier {
  final List<Trade> trades = [
    Trade(pair: 'XAU/USD', direction: 'Long', entry: 2045.3, stopLoss: 2038.5, takeProfit: 2059.8, lot: 0.5, createdAt: DateTime.now(), profit: 245),
    Trade(pair: 'EUR/USD', direction: 'Short', entry: 1.0856, stopLoss: 1.0823, takeProfit: 1.0789, lot: 0.3, createdAt: DateTime.now().subtract(const Duration(days: 1)), profit: 166),
    Trade(pair: 'BTC/USD', direction: 'Long', entry: 43250, stopLoss: 42890, takeProfit: 44100, lot: 0.1, createdAt: DateTime.now().subtract(const Duration(days: 2)), profit: -180),
  ];

  double get totalProfit => trades.fold(0, (p, e) => p + (e.profit ?? 0));
  double get winRate {
    final total = trades.length;
    final wins = trades.where((t) => (t.profit ?? 0) >= 0).length;
    return total == 0 ? 0 : (wins / total) * 100;
  }
}

