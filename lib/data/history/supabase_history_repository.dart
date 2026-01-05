import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tawaqu3_final/data/history/history_repository.dart';
import 'package:tawaqu3_final/models/history_trade.dart';

class SupabaseHistoryRepository implements HistoryRepository {
  final SupabaseClient _sb;

  /// ✅ IMPORTANT: Replace with your real table or view name in Supabase
  static const String historySource = 'history_trades_view';

  SupabaseHistoryRepository(this._sb);

  @override
  Future<List<HistoryTrade>> fetchHistory() async {
    final res = await _sb
        .from(historySource)
        .select(
          'id, trade_id, previous_entry, previous_sl, previous_tp, previous_lot, date_saved, outcome, fname, lname, count',
        )
        .order('date_saved', ascending: false);

    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(HistoryTrade.fromMap).toList();
  }
}
