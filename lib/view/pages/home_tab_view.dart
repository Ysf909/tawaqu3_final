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
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final bool isWide = width >= 800; // tablet / web breakpoint

          // ---------- Balance Card ----------
          final Widget balanceCard = CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Balance'),
                const SizedBox(height: 8),
                Text(
                  '\$24,580.00', // same placeholder value you had before
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text('+ \$1,245 (5.3%) this month'),
              ],
            ),
          );

          // ---------- Markets Card ----------
          final Widget marketsCard = CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Markets'),
                const SizedBox(height: 12),

                if (prices.isEmpty)
                  // same loading state, but works on any screen size
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: Text(
                        'Loading prices…',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...prices.entries.map(
                    (e) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        e.key,
                        overflow: TextOverflow.ellipsis,
                      ),
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
          );

          return SingleChildScrollView(
            // On wide screens, add side padding to avoid super-wide content
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? width * 0.15 : 16,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle('Tawaqu3', Title: '',),
                const SizedBox(height: 16),

                // On wide screens → show cards side-by-side.
                // On mobile → stack them vertically (old behavior).
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: balanceCard),
                      const SizedBox(width: 16),
                      Expanded(child: marketsCard),
                    ],
                  )
                else ...[
                  balanceCard,
                  const SizedBox(height: 16),
                  marketsCard,
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
