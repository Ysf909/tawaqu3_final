import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/history_trade.dart';

class HistoryRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> insertHistoryTrade(HistoryTrade trade) async {
    await _client.from('history').insert({
      'user_id': trade.userId,
      'trade_id': trade.tradeId,
      'previous_entry': trade.previousEntry,
      'previous_sl': trade.previousSl,
      'previous_tp': trade.previousTp,
      'previous_lot': trade.previousLot,
      'date_saved': trade.dateSaved.toIso8601String(),
    });
  }

  Future<List<HistoryTrade>> getHistoryForUser(String userId) async {
    final response = await _client
        .from('history')
        .select()
        .eq('user_id', userId)
        .order('date_saved', ascending: false);

    final List data = response as List;
    return data
        .map((m) => HistoryTrade.fromMap(m as Map<String, dynamic>))
        .toList();
  }
}
