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
          const SectionTitle('Result', Title: ''),
          const SizedBox(height: 8),
          Text(
            'Your trade recommendation is generated from the selected model + latest candles.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),

          if (vm.lastError != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.error.withOpacity(0.25)),
              ),
              child: Text(
                vm.lastError!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (vm.lastPrediction == null) ...[
            const SizedBox(height: 8),
            Text(
              'No prediction yet. Go back and press “Generate Prediction”.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ] else ...[
            // Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        vm.lastPrediction!.pair,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: theme.colorScheme.primary.withOpacity(0.12),
                        ),
                        child: Text(
                          vm.lastPrediction!.side,
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Spacer(),
                      Text('TF: ${vm.tf}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Model: ${vm.selectedModel.label}', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 10),
                  Text(
                    'Confidence: ${vm.lastPrediction!.confidence.toStringAsFixed(1)}%',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: (vm.lastPrediction!.confidence / 100).clamp(0, 1),
                    minHeight: 6,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Levels
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Entry: ${vm.lastPrediction!.entry.toStringAsFixed(4)}'),
                  const SizedBox(height: 6),
                  Text('Stop Loss: ${vm.lastPrediction!.sl.toStringAsFixed(4)}'),
                  const SizedBox(height: 6),
                  Text('Take Profit: ${vm.lastPrediction!.tp.toStringAsFixed(4)}'),
                  const SizedBox(height: 6),
                  Text('Lot: ${vm.lastPrediction!.lot.toStringAsFixed(2)}'),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Outcome buttons (updates trade + history + profit)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: vm.loading ? null : () => vm.markOutcome(TradeOutcome.tpHit),
                    child: const Text('TP HIT'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: vm.loading ? null : () => vm.markOutcome(TradeOutcome.slHit),
                    child: const Text('SL HIT'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
