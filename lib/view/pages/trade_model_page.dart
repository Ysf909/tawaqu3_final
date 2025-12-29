import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/section_title.dart';
import '../../view_model/trade_view_model.dart';
import 'package:tawaqu3_final/models/trade_models.dart';

class TradeModelPage extends StatelessWidget {
  const TradeModelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TradeViewModel>();
    final theme = Theme.of(context);

    final typeLabel = vm.selectedType.label;
    final modelLabel = vm.selectedModel.label;

    String description;
    switch (vm.selectedModel) {
      case TradingModel.ict:
        description = 'ICT model applied for $typeLabel trading.';
        break;
      case TradingModel.smc:
        description = 'SMC model applied for $typeLabel trading.';
        break;
      case TradingModel.trend:
        description = 'Trend-following model applied for $typeLabel trading.';
        break;
    }

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Model (auto-selected)', Title: ''),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.auto_fix_high),
              const SizedBox(width: 8),
              Text(
                modelLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Text(
            'You chose: $typeLabel → model is locked to $modelLabel.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
