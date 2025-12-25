import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/models/market_model.dart';
import 'package:tawaqu3_final/services/api_service.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/section_title.dart';
import 'package:tawaqu3_final/view_model/portfolio_view_model.dart';

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
    final portfolio = context.watch<PortfolioViewModel>();

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final bool isWide = width >= 800;

          final Widget balanceCard = CardContainer(
            child: portfolio.loading
                ? const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Balance'),
                      const SizedBox(height: 8),
                      Text(
                        '\$${portfolio.totalBalance.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${portfolio.monthlyProfit >= 0 ? '+' : '-'} '
                        '\$${portfolio.monthlyProfit.abs().toStringAsFixed(2)} '
                        '(${portfolio.monthlyPercent.toStringAsFixed(1)}%) this month',
                        style: TextStyle(
                          color: portfolio.monthlyProfit >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
          );

          // marketsCard: keep as you have it
          final Widget marketsCard = CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Markets'),
                const SizedBox(height: 12),
                if (prices.isEmpty)
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
                  ...prices.entries.map((e) {
                    final symbol = e.key;
                    final market = e.value;
                    final price = market.price;
                    final change24h =
                        market.change24h; // null for XAU/EUR initially

                    final prev = previousPrices[symbol];

                    // default color = normal text color
                    Color priceColor =
                        Theme.of(context).textTheme.bodyMedium?.color ??
                        Colors.black;

                    if (prev != null) {
                      if (price > prev) {
                        priceColor = Colors.green;
                      } else if (price < prev) {
                        priceColor = Colors.red;
                      }
                    }

                    String? changeText;
                    Color? changeColor;

                    // We only have change24h from Binance for BTC/ETH
                    if (change24h != null) {
                      final sign = change24h >= 0 ? '+' : '';
                      changeText = '$sign${change24h.toStringAsFixed(2)}%';
                      changeColor = change24h >= 0 ? Colors.green : Colors.red;
                    }

                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(symbol, overflow: TextOverflow.ellipsis),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            price.toStringAsFixed(2),
                            style: TextStyle(
                              color: priceColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (changeText != null)
                            Text(
                              changeText,
                              style: TextStyle(
                                color: changeColor,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),

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
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? width * 0.15 : 16,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle('Tawaqu3', Title: ''),
                const SizedBox(height: 16),
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
