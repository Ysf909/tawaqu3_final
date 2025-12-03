import 'package:flutter/material.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/section_title.dart';

class TopTradersTabView extends StatelessWidget {
  const TopTradersTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Top Traders', Title: '',),
          CardContainer(
            child: Column(
              children: const [
                ListTile(
                  leading: CircleAvatar(child: Text('AB')),
                  title: Text('Alice Brown'),
                  subtitle: Text('Profit: +\$5,200 • Win Rate: 78%'),
                ),
                ListTile(
                  leading: CircleAvatar(child: Text('CD')),
                  title: Text('Charlie Davis'),
                  subtitle: Text('Profit: +\$4,750 • Win Rate: 74%'),
                ),
                ListTile(
                  leading: CircleAvatar(child: Text('EF')),
                  title: Text('Eve Foster'),
                  subtitle: Text('Profit: +\$4,300 • Win Rate: 72%'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
