import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/models/trade_models.dart';

import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/section_title.dart';
import '../../view_model/trade_view_model.dart';

class TradeTypePage extends StatelessWidget {
  const TradeTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TradeViewModel>();
    final theme = Theme.of(context);

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Select Trading Type', Title: ''),
          const SizedBox(height: 12),
          Text(
            'Choose how you want to trade. This will control the model and risk style.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Center(
            child: ToggleButtons(
              isSelected:
                  vm.allTypes.map((t) => vm.selectedType == t).toList(),
              onPressed: (index) {
                vm.selectedType = vm.allTypes[index];
              },
              borderRadius: BorderRadius.circular(12),
              constraints: const BoxConstraints(minHeight: 40, minWidth: 90),
              children: vm.allTypes
                  .map(
                    (t) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Text(
                        t.label,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Long: buy & hold • Short: profit from decline • Scalper: quick trades',
          ),
        ],
      ),
    );
  }
}
