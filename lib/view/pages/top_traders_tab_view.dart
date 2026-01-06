import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../view_model/top_traders_view_model.dart';

class TopTradersTabView extends StatefulWidget {
  const TopTradersTabView({super.key});

  @override
  State<TopTradersTabView> createState() => _TopTradersTabViewState();
}

class _TopTradersTabViewState extends State<TopTradersTabView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TopTradersViewModel>().load(limit: 20);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TopTradersViewModel>(
      builder: (context, vm, _) {
        if (vm.loading && vm.traders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.error != null && vm.traders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Failed to load top traders'),
                  const SizedBox(height: 8),
                  Text(vm.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => vm.load(limit: 20),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => vm.load(limit: 20),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: vm.traders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final t = vm.traders[i];

              // ✅ profit text based on nullable totalProfit
              final profitText = t.totalProfit == null
                  ? 'Hidden 🔒'
                  : t.totalProfit!.toStringAsFixed(2);

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(child: Text('${i + 1}')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _chip('Win%', '${t.winRate.toStringAsFixed(1)}%'),
                              _chip(
                                'Model',
                                t.mostUsedModel.isEmpty ? 'ICT' : t.mostUsedModel,
                              ),
                              _chip(
                                'Asset',
                                t.mostUsedAsset.isEmpty ? '—' : t.mostUsedAsset,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Profit'),
                        Text(
                          profitText, // ✅ runtime value (no const)
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

Widget _chip(String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: Colors.grey.withOpacity(0.12),
    ),
    child: Text('$label: $value'),
  );
}
