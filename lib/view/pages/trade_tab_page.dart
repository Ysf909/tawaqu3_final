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
          const SectionTitle('Trading Setup', Title: ''),
          const SizedBox(height: 12),
          Text(
            'Choose instrument, timeframe, then your trading style.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),

          // Pair + TF
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: vm.pair,
                  decoration: const InputDecoration(
                    labelText: 'Pair',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: TradeViewModel.supportedPairs
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    vm.pair = v;
                  },
                ),
              ),
              const SizedBox(width: 12),
              ToggleButtons(
                isSelected: ['1m', '5m'].map((t) => vm.tf == t).toList(),
                onPressed: (index) {
                  vm.tf = (index == 0) ? '1m' : '5m';
                },
                borderRadius: BorderRadius.circular(12),
                constraints: const BoxConstraints(minHeight: 44, minWidth: 56),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('1m'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('5m'),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          Text(
            'Model auto-selected: ${vm.selectedModel.label}',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 18),

          // Trading type
          Center(
            child: ToggleButtons(
              isSelected: vm.allTypes.map((t) => vm.selectedType == t).toList(),
              onPressed: (index) {
                vm.selectedType = vm.allTypes[index];
              },
              borderRadius: BorderRadius.circular(12),
              constraints: const BoxConstraints(minHeight: 40, minWidth: 90),
              children: vm.allTypes
                  .map(
                    (t) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Text(
                        t.label,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 16),
          const Text('Long: buy & hold • Short: profit from decline • Scalper: quick trades'),
        ],
      ),
    );
  }
}
