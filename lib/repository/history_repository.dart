import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tawaqu3_final/models/trade_models.dart';
import '../models/history_trade.dart';

class HistoryRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Insert one history row for a given trade
  Future<HistoryTrade> insertHistoryForTrade({
    required String tradeId, // uuid from trades.id
    double? previousEntry,
    double? previousSl,
    double? previousTp,
    double? previousLot,
    DateTime? dateSaved,
    TradeOutcome? outcome,
  }) async {
    try {
      final response = await _client
          .from('history')
          .insert({
            'trade_id': tradeId,
            'previous_entry': previousEntry,
            'previous_sl': previousSl,
            'previous_tp': previousTp,
            'previous_lot': previousLot,
            'date_saved': (dateSaved ?? DateTime.now()).toIso8601String(),
            'outcome': outcome?.dbValue,
          })
          .select()
          .maybeSingle();

      if (response == null) {
        throw Exception('Failed to insert history row');
      }

      return HistoryTrade.fromMap(response);
    } on PostgrestException catch (e) {
      debugPrint('❌ Supabase error inserting history: ${e.message}');
      debugPrint('code: ${e.code}, details: ${e.details}, hint: ${e.hint}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Unknown error inserting history: $e');
      rethrow;
    }
  }

  /// This is the method your HistoryViewModel is calling.
  /// It gets all history rows for trades that belong to a given user_id.
  Future<List<HistoryTrade>> getHistoryForUser(String userId) async {
    final response = await _client
        .from('history')
        // join history -> trades (inner join) and filter by trades.user_id
        .select(
          'id, trade_id, previous_entry, previous_sl, previous_tp, previous_lot, date_saved, trades!inner(user_id)',
        )
        .eq('trades.user_id', userId)
        .order('date_saved', ascending: false);

    final List data = response as List;

    // HistoryTrade.fromMap ignores the nested "trades" field, which is fine
    return data
        .map((m) => HistoryTrade.fromMap(m as Map<String, dynamic>))
        .toList();
  }
}
