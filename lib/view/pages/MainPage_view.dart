import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/models/market_model.dart';
import 'package:tawaqu3_final/services/price_websocket_service.dart';
import 'package:tawaqu3_final/view/pages/trade_flow_view.dart';
import 'package:tawaqu3_final/view/widgets/tab_nav_bar.dart';
import 'package:tawaqu3_final/view/pages/home_tab_view.dart';
import 'package:tawaqu3_final/view/pages/news_tab_view.dart';
import 'package:tawaqu3_final/view/pages/top_traders_tab_view.dart';
import '../../core/router/app_router.dart';
import '../../view_model/navigation_view_model.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final Map<String, MarketPrice> _prices = {};
  Map<String, double> _previousPrices = {};

  late final PriceWebSocketService _ws = PriceWebSocketService.instance;
  StreamSubscription<Map<String, MarketPrice>>? _priceSub;

  @override
  void initState() {
    super.initState();
    _seedSymbols();
    _startWebSocket();
  }

  void _seedSymbols() {
    // Use symbols WITHOUT underscore. Your WS bridge accepts XAUUSD and maps to XAUUSD_. (server.js)
    const symbols = <String>['XAUUSD', 'XAGUSD', 'BTCUSD', 'ETHUSD', 'EURUSD'];

    final now = DateTime.now().toUtc();
    for (final s in symbols) {
      _prices[s] = MarketPrice(
        symbol: s,
        price: 0,
        mid: 0,
        buy: 0,
        sell: 0,
        change24h: 0,
        time: now,
      );
    }

    _previousPrices = {
      for (final e in _prices.entries) e.key: e.value.effectiveMid,
    };

    if (mounted) setState(() {});
  }

  void _startWebSocket() {
    // IMPORTANT: connect() so pricesStream actually emits
    unawaited(_ws.connect());

    _priceSub = _ws.pricesStream.listen((wsPrices) {
      if (!mounted) return;

      setState(() {
        // save previous mid for color direction
        _previousPrices = {
          for (final e in _prices.entries) e.key: e.value.effectiveMid,
        };

        wsPrices.forEach((symbol, mp) {
          final key = symbol.toUpperCase();
          _prices[key] = mp;
        });
      });
    });
  }

  @override
  void dispose() {
    _priceSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<NavigationViewModel>(context);
    final theme = Theme.of(context);

    final pages = <Widget>[
      HomeTabView(
        prices: _prices,
        previousPrices: _previousPrices,
        onTradeTap: () => nav.setIndex(1),
      ),
      const NewsView(),
      const TradeFlowView(),
      const TopTradersTabView(),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.menuRoute);
            },
            icon: const Icon(Icons.menu),
          ),
        ],
      ),
      body: Container(
        color: theme.colorScheme.surface,
        child: pages[nav.currentIndex],
      ),
      bottomNavigationBar: const TabNavBar(),
    );
  }
}
