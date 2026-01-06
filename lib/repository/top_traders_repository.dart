import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/top_traders_stats.dart';

class TopTradersRepository {
  final SupabaseClient _client;

  TopTradersRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<TopTrader>> fetchTopTraders({int limit = 20}) async {
    final res = await _client.rpc('get_top_traders', params: {'p_limit': limit});

    final list = (res as List)
        .map((e) => TopTrader.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return list;
  }
}
