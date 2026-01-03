import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/top_traders_stats.dart';

class TopTradersRepository {
  final SupabaseClient _client;

  TopTradersRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<List<TopTraderStats>> fetchTopTraders({int limit = 20}) async {
    // We aggregate in Dart because PostgREST "group by" is limited.
    // We'll attempt to select a "pair" column if it exists, otherwise fall back.
    List<dynamic> rows;

    Future<List<dynamic>> runSelect(String select) async {
      final res = await _client.from('trades').select(select).limit(5000);
      return res as List<dynamic>;
    }

    const selectWithPair =
        'user_id, school, outcome, profit, pair, users:users!trades_user_id_fkey(fname,lname)';
    const selectNoPair =
        'user_id, school, outcome, profit, users:users!trades_user_id_fkey(fname,lname)';

    try {
      rows = await runSelect(selectWithPair);
    } catch (_) {
      rows = await runSelect(selectNoPair);
    }

    final Map<String, _Agg> agg = {};

    for (final r in rows) {
      if (r is! Map) continue;
      final m = Map<String, dynamic>.from(r as Map);

      final userId = (m['user_id'] ?? '').toString();
      if (userId.isEmpty) continue;

      final users = (m['users'] is Map)
          ? Map<String, dynamic>.from(m['users'] as Map)
          : const <String, dynamic>{};

      final fname = (users['fname'] ?? '').toString();
      final lname = (users['lname'] ?? '').toString();
      final name = (fname.trim().isEmpty && lname.trim().isEmpty)
          ? 'Trader'
          : '${fname.trim()} ${lname.trim()}'.trim();

      final profit = (m['profit'] as num?)?.toDouble() ?? 0.0;
      final outcome = (m['outcome'] ?? '').toString();
      final model = (m['school'] ?? '').toString();
      final asset = (m['pair'] ?? '').toString(); // optional

      final a = agg.putIfAbsent(userId, () => _Agg(userId: userId, name: name));
      a.totalProfit += profit;

      if (outcome.isNotEmpty) {
        // We count only closed trades for win%.
        final lower = outcome.toLowerCase();
        if (lower.contains('tp')) {
          a.wins += 1;
          a.closed += 1;
        } else if (lower.contains('sl')) {
          a.closed += 1;
        }
      }

      if (model.isNotEmpty) {
        a.modelCounts[model] = (a.modelCounts[model] ?? 0) + 1;
      }

      if (asset.isNotEmpty) {
        a.assetCounts[asset] = (a.assetCounts[asset] ?? 0) + 1;
      }
    }

    final list = agg.values.map((a) {
      final winPct = a.closed == 0 ? 0.0 : (a.wins / a.closed) * 100.0;
      final mostModel = _maxKey(a.modelCounts) ?? 'ICT';
      final mostAsset = _maxKey(a.assetCounts) ?? '—';
      return TopTraderStats(
        userId: a.userId,
        name: a.name,
        totalProfit: a.totalProfit,
        winRate: winPct,
        mostUsedModel: mostModel,
        mostUsedAsset: mostAsset,
      );
    }).toList();

    list.sort((a, b) {
      final w = b.winRate.compareTo(a.winRate);
      if (w != 0) return w;
      return b.totalProfit.compareTo(a.totalProfit);
    });

    if (list.length > limit) return list.sublist(0, limit);
    return list;
  }
}

String? _maxKey(Map<String, int> m) {
  String? best;
  int bestV = -1;
  m.forEach((k, v) {
    if (v > bestV) {
      bestV = v;
      best = k;
    }
  });
  return best;
}

class _Agg {
  final String userId;
  final String name;
  double totalProfit = 0.0;
  int wins = 0;
  int closed = 0;
  final Map<String, int> modelCounts = {};
  final Map<String, int> assetCounts = {};

  _Agg({required this.userId, required this.name});
}
