


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/section_title.dart';
import 'package:tawaqu3_final/view_model/settings_view_model.dart';

class ConnectsView extends StatelessWidget {
  const ConnectsView({super.key});

@override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final connects = CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Connects'),
          SwitchListTile(
            title: const Text('MT5 (MetaTrader 5)'),
            value: vm.mt5Connected,
            onChanged: vm.setMt5,
          ),
        ],
      ),
    );  
    return connects;
  }
}