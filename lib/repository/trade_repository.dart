import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trade_models.dart';

class TradeRepository {
  final SupabaseClient _client;
  TradeRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String _isoUtc(DateTime dt) => dt.toUtc().toIso8601String(); // keep the 'Z'

  Future<String> createTrade({
    required String userId,
    required double entry,
    required double sl,
    required double tp,
    required double lot,
    required String school,
    required DateTime time,
    required String pair,
    required String side,
    required double confidence, // 0-100
  }) async {
    final res = await _client.rpc('create_trade', params: {
      'p_user_id': userId,
      'p_entry': entry,
      'p_sl': sl,
      'p_tp': tp,
      'p_lot': lot,
      'p_school': school,
      'p_time': _isoUtc(time),
      'p_pair': pair,
      'p_side': side,
      'p_confidence': confidence,
    });

    return res as String; // uuid
  }

  Future<void> closeTrade({
    required String tradeId,
    required TradeOutcome outcome,
    required double profit,
    DateTime? closeTime,
  }) async {
    await _client.rpc('close_trade', params: {
      'p_trade_id': tradeId,
      'p_outcome': outcome.dbValue, // tp_hit / sl_hit
      'p_profit': profit,
      'p_close_time': _isoUtc(closeTime ?? DateTime.now()),
    });
  }
}
