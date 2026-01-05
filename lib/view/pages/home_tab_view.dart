import 'package:flutter/material.dart';
import 'package:tawaqu3_final/models/market_model.dart';
import 'package:tawaqu3_final/view/pages/asset_chart_live_view.dart';

class HomeTabView extends StatelessWidget {
  final Map<String, MarketPrice> prices;
  final Map<String, double> previousPrices;
  final VoidCallback onTradeTap;

  const HomeTabView({
    super.key,
    required this.prices,
    required this.previousPrices,
    required this.onTradeTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final items = prices.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Markets", style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),

          if (items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text("Waiting for live prices…"),
              ),
            )
          else
            ...items.map((entry) {
              final symbol = entry.key.toUpperCase();
              final market = entry.value;

              final price = market.effectiveMid;
              final prev = previousPrices[symbol];

              final isUp = prev == null ? null : price >= prev;
              final priceColor = isUp == null
                  ? theme.colorScheme.onSurface
                  : (isUp ? Colors.green : Colors.red);

              final change = market.change24h;
              final changeText = (change == null)
                  ? "--"
                  : "${change >= 0 ? "+" : ""}${change.toStringAsFixed(2)}%";

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(child: Text(symbol.substring(0, 1))),
                  title: Text(symbol),
                  subtitle: Text("24h: $changeText"),
                  trailing: Text(
                    price == 0 ? "--" : price.toStringAsFixed(2),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: priceColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AssetChartLiveView(symbol: symbol, initialTf: "5m"),
                      ),
                    );
                  },
                ),
              );
            }),

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.auto_graph),
              label: const Text("Go to Trade"),
              onPressed: onTradeTap,
            ),
          ),
        ],
      ),
    );
  }
}
