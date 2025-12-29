import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PortfolioViewModel extends ChangeNotifier {
  bool _loading = false;
  bool _loadedOnce = false;

  double _totalBalance = 0.0;   // we will show "profit" as total balance (per your request)
  double _monthlyProfit = 0.0;
  double _monthlyPercent = 0.0;

  bool get loading => _loading;
  double get totalBalance => _totalBalance;
  double get monthlyProfit => _monthlyProfit;
  double get monthlyPercent => _monthlyPercent;

  void ensureLoaded() {
    if (_loading || _loadedOnce) return;
    load();
  }

  Future<void> load() async {
    final supabase = Supabase.instance.client;
    final uid = supabase.auth.currentUser?.id;

    if (uid == null) {
      _totalBalance = 0;
      _monthlyProfit = 0;
      _monthlyPercent = 0;
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      // 1) Read user profit (your schema has users.profit)
      final userRow = await supabase
          .from('users')
          .select('profit')
          .eq('id', uid)
          .single();

      final userProfit = (userRow['profit'] as num?)?.toDouble() ?? 0.0;

      // 2) Read trades profit + time
      final trades = await supabase
          .from('trades')
          .select('profit,time')
          .eq('user_id', uid);

      double totalTradesProfit = 0.0;
      double monthProfit = 0.0;

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      for (final t in (trades as List)) {
        final p = (t['profit'] as num?)?.toDouble() ?? 0.0;
        totalTradesProfit += p;

        final rawTime = t['time'];
        DateTime? dt;
        if (rawTime is String) dt = DateTime.tryParse(rawTime);
        if (rawTime is DateTime) dt = rawTime;

        if (dt != null && dt.isAfter(monthStart)) {
          monthProfit += p;
        }
      }

      // If you maintain users.profit, we show it.
      // Otherwise fallback to sum(trades.profit).
      _totalBalance = userProfit != 0.0 ? userProfit : totalTradesProfit;

      _monthlyProfit = monthProfit;

      final startOfMonthBalance = _totalBalance - _monthlyProfit;
      if (startOfMonthBalance.abs() > 0.000001) {
        _monthlyPercent = (_monthlyProfit / startOfMonthBalance) * 100.0;
      } else {
        _monthlyPercent = 0.0;
      }

      _loadedOnce = true;
    } catch (e) {
      debugPrint('Portfolio load error: $e');
      _totalBalance = 0;
      _monthlyProfit = 0;
      _monthlyPercent = 0;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
