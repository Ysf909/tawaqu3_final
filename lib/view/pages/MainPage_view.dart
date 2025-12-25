import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/models/market_model.dart';
import 'package:tawaqu3_final/services/mt5_tick_websocket_service.dart';
import 'package:tawaqu3_final/view/pages/trade_flow_view.dart';
import 'package:tawaqu3_final/view/widgets/tab_nav_bar.dart';
import 'package:tawaqu3_final/view/pages/home_tab_view.dart';
import 'package:tawaqu3_final/view/pages/news_tab_view.dart';
import 'package:tawaqu3_final/view/pages/top_traders_tab_view.dart';
import '../../core/router/app_router.dart';
import '../../view_model/navigation_view_model.dart';
import '../../services/api_service.dart' show ApiService;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _wsUrl() {
    // Web (Chrome on PC): localhost
    if (kIsWeb) return 'ws://127.0.0.1:8080';

    // Android emulator:
    // 10.0.2.2 maps to your PC (host)
    return 'ws://10.0.2.2:8080';

    // If you test on real phone, replace with:
    // return 'ws://192.168.1.29:8080';
  }

  final _api = ApiService();

  Map<String, MarketPrice> _prices = {};
  Map<String, double> _previousPrices = {};

  Mt5TickWebSocketService? _wsService;
  StreamSubscription<Map<String, MarketPrice>>? _wsSub;

  void _seedSymbols() {
    const symbols = <String>['EURUSD_', 'XAUUSD_', 'BTCUSD', 'ETHUSD'];

    setState(() {
      _prices = {
        for (final s in symbols)
          s: const MarketPrice(price: 0.0, change24h: null),
      };
      _previousPrices = {for (final s in symbols) s: 0.0};
    });
  }

  @override
  void initState() {
    super.initState();
    _seedSymbols();
    _startWebSocket();
  }

  void _startWebSocket() {
    _wsService = Mt5TickWebSocketService(wsUrl: _wsUrl());
    _wsSub = _wsService!.pricesStream.listen((wsPrices) {
      print(
        "WS PRICES: $wsPrices",
      ); // ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã¢â‚¬Å“ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ add this
      if (!mounted) return;

      setState(() {
        _previousPrices = {
          for (final entry in _prices.entries) entry.key: entry.value.price,
        };

        wsPrices.forEach((symbol, marketPrice) {
          final key = symbol.toUpperCase();
          _prices[key] = marketPrice;
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
      // convert Map<String, double> ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ Map<String, MarketPrice>
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
        // from Home "Trade" button ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢ go to Trade tab (index 2)
        onTradeTap: () => nav.setIndex(2),
      ),
      const NewsView(),
      const TradeFlowView(), // ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â°ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¸ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¹Ãƒâ€¦Ã¢â‚¬Å“ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¹ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â  your 4-step flow as the Trade tab
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
      body: tabs[nav.currentIndex],
      bottomNavigationBar: const TabNavBar(),
    );
  }
}
