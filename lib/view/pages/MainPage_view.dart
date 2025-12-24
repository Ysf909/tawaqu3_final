import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/services/price_websocket_service.dart';
import 'package:tawaqu3_final/view/pages/trade_flow_view.dart';
import 'package:tawaqu3_final/view/widgets/tab_nav_bar.dart';
import 'package:tawaqu3_final/view/pages/home_tab_view.dart';
import 'package:tawaqu3_final/view/pages/news_tab_view.dart';
import 'package:tawaqu3_final/view/pages/top_traders_tab_view.dart';
import '../../core/router/app_router.dart';
import '../../view_model/navigation_view_model.dart';
import '../../services/api_service.dart';                 // MarketPrice is here

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _api = ApiService();

Map<String, MarketPrice> _prices = {};
Map<String, double> _previousPrices = {};

PriceWebSocketService? _wsService;
StreamSubscription<Map<String, MarketPrice>>? _wsSub;


  @override
void initState() {
  super.initState();
  _loadInitialPrices();
  _startWebSocket();
}

void _startWebSocket() {
  _wsService = PriceWebSocketService();
  _wsSub = _wsService!.pricesStream.listen((wsPrices) {
  print("WS PRICES: $wsPrices"); // ✅ add this
  if (!mounted) return;

  setState(() {
    _previousPrices = {
      for (final entry in _prices.entries) entry.key: entry.value.price,
    };

    wsPrices.forEach((symbol, marketPrice) {
      _prices[symbol] = marketPrice;
    });
  });
});

}

@override
void dispose() {
  _wsSub?.cancel();
  _wsService?.dispose();
  super.dispose();
}

  Future<void> _loadInitialPrices() async {
  // uses your existing ApiService.fetchAllOnce()
  final raw = await _api.fetchAllOnce(); // Map<String, double>

  if (!mounted) return;

  setState(() {
    // convert Map<String, double> → Map<String, MarketPrice>
    _prices = raw.map(
      (symbol, price) => MapEntry(
        symbol,
        MarketPrice(
          price: price,
          change24h: null, // WebSocket will override this for BTC/ETH
        ),
      ),
    );

    _previousPrices = {
      for (final entry in _prices.entries) entry.key: entry.value.price,
    };
  });
}

@override
Widget build(BuildContext context) {
  final nav = context.watch<NavigationViewModel>();

  final tabs = [
    HomeTabView(
      prices: _prices,
      previousPrices: _previousPrices,
      // from Home "Trade" button → go to Trade tab (index 2)
      onTradeTap: () => nav.setIndex(2),
    ),
    const NewsView(),
    const TradeFlowView(),       // 👈 your 4-step flow as the Trade tab
    const TopTradersTabView(),
  ];

  return Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const SizedBox.shrink(),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.pushNamed(
              context,
              AppRouter.menuRoute,
            );
          },
          icon: const Icon(Icons.menu),
        ),
      ],
    ),
    body: tabs[nav.currentIndex],
    bottomNavigationBar: const TabNavBar(),
  );
}
}