import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/section_title.dart';
import 'package:tawaqu3_final/view/widgets/primary_button.dart';
import '../../view_model/trade_view_model.dart';
import '../../models/trade_models.dart';

class TradeFlowView extends StatelessWidget {
  const TradeFlowView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TradeViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Trade Generation Flow')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          final sections = <Widget>[
            _TypeSection(vm: vm),
            _ModelSection(vm: vm),   // shows fixed model, not editable
            _MarginSection(vm: vm),
            _ResultSection(vm: vm),
          ];

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sections
                  .map((w) => Expanded(child: SingleChildScrollView(child: w)))
                  .toList(),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(8),
            children: sections,
          );
        },
      ),
    );

      
  }
}

  class _TypeSection extends StatelessWidget {
  final TradeViewModel vm;
  const _TypeSection({required this.vm});

   @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Select Trading Type', Title: ''),
          const SizedBox(height: 8),
          ToggleButtons(
            isSelected: vm.allTypes
                .map((t) => vm.selectedType == t)
                .toList(),
            onPressed: (index) {
              vm.selectedType = vm.allTypes[index];
            },
            children: vm.allTypes
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(t.label), // from TradingTypeLabel extension
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          const Text(
            'Long: buy & hold • Short: profit from decline • Scalper: quick trades',
          ),
        ],
      ),
    );
  }
}

class _ModelSection extends StatelessWidget {
  final TradeViewModel vm;
  const _ModelSection({required this.vm});

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.auto_fix_high),
              const SizedBox(width: 8),
              Text(
                modelLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(description),
          const SizedBox(height: 8),
          Text(
            'You chose: $typeLabel → model is locked to $modelLabel.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
class _MarginSection extends StatelessWidget {
  final TradeViewModel vm;
  const _MarginSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Account & Risk', Title: ''),
          const SizedBox(height: 8),

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
          const SizedBox(height: 12),

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
          ),
          const SizedBox(height: 16),

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
class _ResultSection extends StatelessWidget {
  final TradeViewModel vm;
  const _ResultSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Trade Prediction', Title: ''),
          const SizedBox(height: 8),
          if (vm.lastPrediction == null)
            const Text('No prediction yet.')
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${vm.selectedType.label}'),
                Text('Model: ${vm.selectedModel.label}'),
                const SizedBox(height: 4),
                Text('Pair: ${vm.lastPrediction!.pair}'),
                Text('Entry: ${vm.lastPrediction!.entry.toStringAsFixed(4)}'),
                Text('Stop Loss: ${vm.lastPrediction!.sl.toStringAsFixed(4)}'),
                Text('Take Profit: ${vm.lastPrediction!.tp.toStringAsFixed(4)}'),
                Text(
                    'Recommended Lot: ${vm.lastPrediction!.lot.toStringAsFixed(2)}'),
                Text('Confidence: ${vm.lastPrediction!.confidence}%'),
              ],
            ),
        ],
      ),
    );
  }
}
