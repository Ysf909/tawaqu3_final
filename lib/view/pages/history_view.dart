import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/section_title.dart';
import '../../view_model/history_view_model.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryViewModel>();

    final tradeHistory = CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('History'),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(
                  'Total Profit: +\$${history.totalProfit.toStringAsFixed(2)}',
                ),
              ),
              Chip(
                label: Text(
                  'Win Rate: ${history.winRate.toStringAsFixed(1)}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...history.trades.map(
            (t) => ListTile(
              title: Text('${t.pair} · ${t.direction}'),
              subtitle: Text(
                'Entry ${t.entry} • Exit ${t.takeProfit} • Lot ${t.lot}',
              ),
              trailing: Text(
                (t.profit ?? 0) >= 0
                    ? '+\$${t.profit!.toStringAsFixed(0)}'
                    : '-\$${(t.profit! * -1).toStringAsFixed(0)}',
                style: TextStyle(
                  color: (t.profit ?? 0) >= 0
                      ? Colors.greenAccent
                      : Colors.redAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [tradeHistory],
      ),
    );
  }
}
