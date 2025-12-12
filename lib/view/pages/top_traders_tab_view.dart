import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tawaqu3_final/models/top_traders_stats.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/section_title.dart';

class TopTradersTabView extends StatefulWidget {
  const TopTradersTabView({super.key});

  @override
  State<TopTradersTabView> createState() => _TopTradersTabViewState();
}

class _TopTradersTabViewState extends State<TopTradersTabView> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _loading = false;
  List<TopTraderStats> _topTraders = [];

  @override
  void initState() {
    super.initState();
    _loadTopTraders();
  }

  Future<void> _loadTopTraders() async {
    setState(() => _loading = true);

    try {
      // 1) Load all trades joined with users to get names
      final res = await _client
          .from('trades')
          .select(
            '''
            fname, lname,
            school,
            outcome,
            profit,
           
            ''',
          );

      final List data = res as List;

      // 2) Aggregate per user in Dart
      final Map<String, _UserAgg> byUser = {};

      for (final row in data) {
        final map = row as Map<String, dynamic>;
        final String userId = map['user_id'] as String;

        final userMap = map['users'] as Map<String, dynamic>;
        final String fname = userMap['fname'] as String? ?? '';
        final String lname = userMap['lname'] as String? ?? '';
        final String fullName = '$fname $lname'.trim();

        final String school = (map['school'] as String?) ?? 'Unknown';
        final String? outcomeStr = map['outcome'] as String?;
        final double profit =
            (map['profit'] as num?)?.toDouble() ?? 0.0;

        final agg = byUser.putIfAbsent(
          userId,
          () => _UserAgg(
            userId: userId,
            name: fullName.isEmpty ? 'Unknown' : fullName,
          ),
        );

        // accumulate profit (for ranking only)
        agg.totalProfit += profit;

        // count model usage
        agg.modelCounts[school] = (agg.modelCounts[school] ?? 0) + 1;

        // win / loss based on outcome
        if (outcomeStr == 'tp_hit' || outcomeStr == 'sl_hit') {
          agg.closedTrades++;
          if (outcomeStr == 'tp_hit') {
            agg.wins++;
          }
        }
      }

      // 3) Convert aggregates → TopTraderStats
      final stats = <TopTraderStats>[];

      for (final agg in byUser.values) {
        if (agg.closedTrades == 0) {
          // we can skip users with no closed trades, or include them with 0% win rate
          continue;
        }

        // most used model
        String mostUsedModel = 'Unknown';
        int bestCount = 0;
        agg.modelCounts.forEach((model, count) {
          if (count > bestCount) {
            bestCount = count;
            mostUsedModel = model;
          }
        });

        final double winRate =
            (agg.wins / agg.closedTrades) * 100.0;

        stats.add(
          TopTraderStats(
            userId: agg.userId,
            name: agg.name,
            mostUsedModel: mostUsedModel,
            winRate: winRate,
            totalProfit: agg.totalProfit,
          ),
        );
      }

      // 4) Sort by totalProfit desc (top money makers) & keep top 5
      stats.sort((a, b) => b.totalProfit.compareTo(a.totalProfit));
      _topTraders = stats.take(5).toList();
    } catch (e, st) {
      debugPrint('loadTopTraders error: $e\n$st');
      _topTraders = [];
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Top Traders', Title: ''),
          const SizedBox(height: 8),
          CardContainer(
            child: _loading
                ? const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _topTraders.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No top traders yet. Close some trades with TP/SL to see stats here.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : Column(
                        children: _topTraders.map((t) {
                          final initials = _initialsFromName(t.name);
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(initials),
                            ),
                            title: Text(t.name),
                            subtitle: Text(
                              'Most used model: ${t.mostUsedModel} • '
                              'Win rate: ${t.winRate.toStringAsFixed(1)}%',
                            ),
                          );
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }
}

/// Internal aggregator used while building the stats
class _UserAgg {
  final String userId;
  final String name;
  double totalProfit = 0;
  int wins = 0;
  int closedTrades = 0;
  final Map<String, int> modelCounts = {};

  _UserAgg({
    required this.userId,
    required this.name,
  });
}

/// Helper to build initials from the full name
String _initialsFromName(String name) {
  final parts = name.trim().split(' ');
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.isNotEmpty
        ? parts.first[0].toUpperCase()
        : '?';
  }
  final first = parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
  final second = parts[1].isNotEmpty ? parts[1][0].toUpperCase() : '';
  final initials = '$first$second';
  return initials.isEmpty ? '?' : initials;
}
