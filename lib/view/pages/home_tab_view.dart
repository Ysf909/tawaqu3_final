import 'package:flutter/material.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/section_title.dart';

class HomeTabView extends StatelessWidget {
  final Map<String, double> prices;
  final VoidCallback onTradeTap;

  const HomeTabView({
    super.key,
    required this.prices,
    required this.onTradeTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Tawaqu3'),
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Balance'),
                const SizedBox(height: 8),
                Text(
                  '\$24,580.00',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text('+ \$1,245 (5.3%) this month'),
              ],
            ),
          ),
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Markets'),
                const SizedBox(height: 12),
                ...prices.entries.map(
                  (e) => ListTile(
                    title: Text(e.key),
                    trailing: Text(e.value.toStringAsFixed(2)),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onTradeTap,
                    child: const Text('Trade'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
