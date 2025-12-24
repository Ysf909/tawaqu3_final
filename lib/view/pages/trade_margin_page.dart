import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/section_title.dart';
import 'package:tawaqu3_final/view/widgets/primary_button.dart';
import '../../view_model/trade_view_model.dart';

class TradeMarginPage extends StatelessWidget {
  const TradeMarginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TradeViewModel>();
    final theme = Theme.of(context);

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Account & Risk', Title: ''),
          const SizedBox(height: 12),
          Text(
            'Define your account size and risk per trade. We’ll calculate a suitable lot size.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: vm.margin.toStringAsFixed(2),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Margin / Account balance (\$)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              final parsed = double.tryParse(value);
              if (parsed != null) vm.margin = parsed;
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Risk per trade',
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: vm.riskPercent,
                  min: 0.5,
                  max: 10,
                  divisions: 95,
                  label: '${vm.riskPercent.toStringAsFixed(1)}%',
                  onChanged: (value) => vm.riskPercent = value,
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '${vm.riskPercent.toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Calculated lot: ${vm.calculatedLot.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'GENERATE PREDICTION',
            loading: vm.loading,
            onPressed: vm.generate,
          ),
        ],
      ),
    );
  }
}
