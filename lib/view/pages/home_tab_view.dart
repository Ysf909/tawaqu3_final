import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/models/market_model.dart';
import 'package:tawaqu3_final/services/api_service.dart';
import 'package:tawaqu3_final/view/pages/asset_chart_live_view.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/section_title.dart';
import 'package:tawaqu3_final/view_model/portfolio_view_model.dart';

class HomeTabView extends StatefulWidget {
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
  State<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends State<HomeTabView> {
  @override
  void initState() {
    super.initState();
    // Load portfolio once after first frame (avoids rebuild loop)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PortfolioViewModel>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final portfolio = context.watch<PortfolioViewModel>();

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isWide = width >= 800;

          final balanceCard = CardContainer(
            child: portfolio.loading
                ? const SizedBox(
                    height: 90,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Balance', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        '\$${portfolio.totalBalance.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${portfolio.monthlyProfit >= 0 ? '+' : '-'}\$${portfolio.monthlyProfit.abs().toStringAsFixed(2)}'
                        ' (${portfolio.monthlyPercent.toStringAsFixed(1)}%) this month',
                        style: TextStyle(
                          color: portfolio.monthlyProfit >= 0
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (portfolio.error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          portfolio.error!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
          );

          final marketsCard = CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Markets', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AssetChartLiveView(
                              symbol: 'XAUUSD',
                              initialTf: '15m',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.show_chart),
                      label: const Text('Open Chart'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (widget.prices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18.0),
                    child: Center(
                      child: Text(
                        'Loading prices…',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...widget.prices.entries.map((e) {
                    final symbol = e.key;
                    final market = e.value;
                    final price = market.price;
                    final change24h = market.change24h;

                    final prev = widget.previousPrices[symbol];

                    Color priceColor =
                        theme.textTheme.bodyMedium?.color ?? Colors.black;
                    if (prev != null) {
                      if (price > prev) priceColor = Colors.green;
                      if (price < prev) priceColor = Colors.red;
                    }

                    String? changeText;
                    Color? changeColor;
                    if (change24h != null) {
                      final sign = change24h >= 0 ? '+' : '';
                      changeText = '$sign${change24h.toStringAsFixed(2)}%';
                      changeColor = change24h >= 0 ? Colors.green : Colors.red;
                    }

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AssetChartLiveView(
                              symbol: symbol,
                              initialTf: '15m',
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: theme.colorScheme.surfaceVariant,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                symbol.isNotEmpty ? symbol[0] : '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    symbol,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Spot',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  price.toStringAsFixed(2),
                                  style: TextStyle(
                                    color: priceColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (changeText != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color:
                                          (changeColor ??
                                                  theme.colorScheme.onSurface)
                                              .withOpacity(0.12),
                                    ),
                                    child: Text(
                                      changeText,
                                      style: TextStyle(
                                        color: changeColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: widget.onTradeTap,
                    child: const Text('Trade'),
                  ),
                ),
              ],
            ),
          );

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? width * 0.12 : 16,
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
