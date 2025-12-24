import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PortfolioViewModel extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  final double baseBalance; // starting balance (e.g., 10,000)
  PortfolioViewModel({this.baseBalance = 10000});

  bool loading = false;
  double totalProfit = 0;    // lifetime P/L
  double monthlyProfit = 0;  // last 30 days

  double get totalBalance => baseBalance + totalProfit;

  double get monthlyPercent {
    if (baseBalance == 0) return 0;
    return (monthlyProfit / baseBalance) * 100;
  }

  Future<void> loadForCurrentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return;

    loading = true;
    notifyListeners();

    try {
      final res = await _client
          .from('trades')
          .select('profit, time')
          .eq('user_id', authUser.id);

      double total = 0;
      double month = 0;
      final now = DateTime.now().toUtc();
      final from = now.subtract(const Duration(days: 30));

      for (final row in res as List) {
        final p = (row['profit'] as num?)?.toDouble() ?? 0.0;
        total += p;

        final timeStr = row['time'] as String;
        final t = DateTime.parse(timeStr).toUtc();
        if (t.isAfter(from)) {
          month += p;
        }
      }

      totalProfit = total;
      monthlyProfit = month;
    } catch (e, st) {
      debugPrint('loadForCurrentUser portfolio error: $e\n$st');
      totalProfit = 0;
      monthlyProfit = 0;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
