import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/section_title.dart';
import 'package:tawaqu3_final/view/widgets/primary_button.dart';
import '../../view_model/trade_view_model.dart';

class TradeFlowView extends StatelessWidget {
  const TradeFlowView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TradeViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Trade Generation Flow')),
      body: LayoutBuilder(
        builder: (context, c) {
          final col = c.maxWidth > 900;
          final type = CardContainer(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Select Trading Type', Title: '',),
              ToggleButtons(
                isSelected: ['Long','Short','Scalper'].map((t)=> vm.selectedType==t).toList(),
                onPressed: (i){ vm.selectedType = ['Long','Short','Scalper'][i]; vm.notifyListeners(); },
                children: const [Padding(padding: EdgeInsets.all(12), child: Text('Long')),
                                  Padding(padding: EdgeInsets.all(12), child: Text('Short')),
                                  Padding(padding: EdgeInsets.all(12), child: Text('Scalper'))],
              ),
              const SizedBox(height: 8),
              const Text('Buy and hold for profit / Profit from price decline / Quick trades'),
            ],
          ));

          final model = CardContainer(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Select Model', Title: '',),
              DropdownButton<String>(
                value: vm.selectedModel,
                items: const [
                  DropdownMenuItem(value: 'ICAT', child: Text('ICAT • 97% Accuracy')),
                  DropdownMenuItem(value: '3M', child: Text('3M • 84% Accuracy')),
                ],
                onChanged: (v){ if (v!=null){ vm.selectedModel = v; vm.notifyListeners(); } },
              ),
              const SizedBox(height: 12),
              Row(children: [
                const Text('Investment Amount: '),
                Expanded(child: Slider(
                  value: vm.amount,
                  min: 100, max: 5000, divisions: 49,
                  label: vm.amount.toStringAsFixed(0),
                  onChanged: (v){ vm.amount = v; vm.notifyListeners(); },
                )),
                Text('\$${vm.amount.toStringAsFixed(0)}'),
              ]),
              PrimaryButton(label: 'GENERATE PREDICTION', loading: vm.loading, onPressed: vm.generate),
            ],
          ));

          final result = CardContainer(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Trade Prediction', Title: '',),
              if (vm.lastPrediction == null) const Text('No prediction yet.'),
              if (vm.lastPrediction != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pair: ${vm.lastPrediction!.pair}'),
                    Text('Entry: ${vm.lastPrediction!.entry.toStringAsFixed(2)}'),
                    Text('Stop Loss: ${vm.lastPrediction!.sl.toStringAsFixed(2)}'),
                    Text('Take Profit: ${vm.lastPrediction!.tp.toStringAsFixed(2)}'),
                    Text('Recommended Lot: ${vm.lastPrediction!.lot.toStringAsFixed(2)}'),
                    Text('Confidence: ${vm.lastPrediction!.confidence}%'),
                  ],
                )
            ],
          ));

          if (col) {
            return Row(children: [Expanded(child: type), Expanded(child: model), Expanded(child: result)]);
          }
          return ListView(children: [type, model, result]);
        },
      ),
    );
  }
}

