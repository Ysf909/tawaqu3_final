import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tawaqu3_final/models/market_model.dart';
import 'package:tawaqu3_final/services/price_websocket_service.dart';
import 'package:tawaqu3_final/view/pages/trade_flow_view.dart';
import 'package:tawaqu3_final/view/widgets/tab_nav_bar.dart';
import 'package:tawaqu3_final/view/pages/home_tab_view.dart';
import 'package:tawaqu3_final/view/pages/news_tab_view.dart';
import 'package:tawaqu3_final/view/pages/top_traders_tab_view.dart';
import 'package:tawaqu3_final/view/widgets/user_profit_card.dart';

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

  // ✅ Profit state
  bool _profitLoading = true;
  double? _userProfit;
  String? _profitError;
  DateTime? _profitUpdatedAt;

  SupabaseClient get _sb => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _seedSymbols();
    _startWebSocket();
    _loadUserProfit(); // ✅ load once when page opens
  }

  void _seedSymbols() {
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
    unawaited(_ws.connect());

    _priceSub = _ws.pricesStream.listen((wsPrices) {
      if (!mounted) return;

      setState(() {
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

  Future<void> _loadUserProfit() async {
    if (!mounted) return;

    setState(() {
      _profitLoading = true;
      _profitError = null;
    });

    try {
      final userId = _sb.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _userProfit = 0;
          _profitUpdatedAt = DateTime.now();
          _profitLoading = false;
        });
        return;
      }

      // ✅ Replace 'trades' with your real table name
      final rows = await _sb
          .from('trades')
          .select('profit')
          .eq('user_id', userId);

      final list = (rows as List);

      double total = 0;
      for (final r in list) {
        final v = (r as Map)['profit'];
        if (v is num) total += v.toDouble();
      }

      if (!mounted) return;
      setState(() {
        _userProfit = total;
        _profitUpdatedAt = DateTime.now();
        _profitLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profitError = e.toString();
        _profitLoading = false;
      });
    }
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
        onTradeTap: () => nav.setIndex(2),
      ),
      const NewsView(),
      const TradeFlowView(),
      const TopTradersTabView(),
    ];

    final current = pages[nav.currentIndex];

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
        child: nav.currentIndex == 0
            ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: UserProfitCard(
                      isLoading: _profitLoading,
                      profit: _userProfit,
                      error: _profitError,
                      updatedAt: _profitUpdatedAt,
                      onRefresh: _loadUserProfit,
                    ),
                  ),
                  Expanded(child: current),
                ],
              )
            : current,
      ),
      bottomNavigationBar: const TabNavBar(),
    );
  }
}
