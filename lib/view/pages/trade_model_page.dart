import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/models/trading_labels.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/section_title.dart';
import '../../view_model/trade_view_model.dart';

class TradeModelPage extends StatelessWidget {
  final VoidCallback? onNext; // ✅ optional to keep compatibility
  const TradeModelPage({super.key, this.onNext});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TradeViewModel>();
    final theme = Theme.of(context);

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Model', Title: ''),
          const SizedBox(height: 8),
          Text(
            'Predictions are generated ONLY by the ICT model until other models are ready.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock),
                const SizedBox(width: 10),
                Text(
                  'Active model: ${vm.selectedModel.label}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ✅ Only show Next if flow provides it
          if (onNext != null)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: vm.loading ? null : onNext,
                child: const Text('Next'),
              ),
            ),
        ],
      ),
    );
  }
}
