import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trade_entity.dart';

class TradeRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<TradeEntity> insertTrade({
    required String userId,
    required double entry,
    required double sl,
    required double tp,
    required double lot,
    required String school,
    required DateTime time,

    // optional extra fields
    String? pair,
    String? side,
    double? confidence,
    String? outcome,
    double? profit,
  }) async {
    final payload = <String, dynamic>{
      'user_id': userId,
      'entry': entry,
      'sl': sl,
      'tp': tp,
      'lot': lot,
      'school': school,
      'time': time.toIso8601String(),

      if (pair != null) 'pair': pair,
      if (side != null) 'side': side,
      if (confidence != null) 'confidence': confidence,
      if (outcome != null) 'outcome': outcome,
      if (profit != null) 'profit': profit,
    };

    final response = await _client
        .from('trades')
        .insert(payload)
        .select()
        .maybeSingle();

    if (response == null) {
      throw Exception('Failed to insert trade');
    }

    return TradeEntity.fromMap(response);
  }
}
