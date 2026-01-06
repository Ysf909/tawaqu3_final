import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tawaqu3_final/models/top_traders_stats.dart';

class TopTradersViewModel extends ChangeNotifier {
  final SupabaseClient _db;
  TopTradersViewModel({SupabaseClient? client})
      : _db = client ?? Supabase.instance.client;

  bool loading = false;
  String? error;
  List<TopTrader> traders = [];

  Future<void> load({int limit = 20}) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final res = await _db.rpc('get_top_traders', params: {'p_limit': limit});
      final list = (res as List).cast<dynamic>();

      traders = list
          .map((e) => TopTrader.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
