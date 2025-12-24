import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/models/trade_models.dart';

import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/section_title.dart';
import '../../view_model/trade_view_model.dart';

class TradeResultPage extends StatelessWidget {
  const TradeResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TradeViewModel>();
    final theme = Theme.of(context);

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Trade Prediction', Title: ''),
          const SizedBox(height: 12),
          if (vm.lastPrediction == null)
            Text(
              'No prediction yet.\nGenerate a trade from the Account & Risk step.',
              style: theme.textTheme.bodyMedium,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overview',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text('Type: ${vm.selectedType.label}'),
                Text('Model: ${vm.selectedModel.label}'),
                const SizedBox(height: 12),
                Text(
                  'Execution',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text('Pair: ${vm.lastPrediction!.pair}'),
                Text(
                    'Entry: ${vm.lastPrediction!.entry.toStringAsFixed(4)}'),
                Text(
                    'Stop Loss: ${vm.lastPrediction!.sl.toStringAsFixed(4)}'),
                Text(
                    'Take Profit: ${vm.lastPrediction!.tp.toStringAsFixed(4)}'),
                Text(
                    'Recommended Lot: ${vm.lastPrediction!.lot.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                Text(
                  'Confidence: ${vm.lastPrediction!.confidence}%',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Row(
  children: [
    Expanded(
      child: OutlinedButton(
        onPressed: vm.loading
            ? null
            : () => vm.markOutcome(TradeOutcome.tpHit),
        child: const Text('TP HIT'),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: OutlinedButton(
        onPressed: vm.loading
            ? null
            : () => vm.markOutcome(TradeOutcome.slHit),
        child: const Text('SL HIT'),
      ),
    ),
  ],
),

              ],
            ),
        ],
      ),
    );
  }
}
