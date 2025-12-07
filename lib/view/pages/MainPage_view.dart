import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/view/widgets/tab_nav_bar.dart';
import 'package:tawaqu3_final/view/pages/home_tab_view.dart';
import 'package:tawaqu3_final/view/pages/news_tab_view.dart';
import 'package:tawaqu3_final/view/pages/trade_tab_view.dart';
import 'package:tawaqu3_final/view/pages/top_traders_tab_view.dart';
import '../../core/router/app_router.dart';
import '../../view_model/navigation_view_model.dart';
import '../../view_model/auth_view_model.dart';
import '../../services/api_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _api = ApiService();
  Map<String, double> _prices = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prices = await _api.fetchAllOnce();
    if (mounted) {
      setState(() {
        _prices = prices;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationViewModel>();
    final auth = context.watch<AuthViewModel>(); // remove if unused

    final tabs = [
      HomeTabView(
        prices: _prices,
        onTradeTap: () => nav.setIndex(2), // go to Trade tab
      ),
      const NewsView(),
      TradeTabView(
        onOpenTradeFlow: () => Navigator.pushNamed(
          context,
          AppRouter.tradeFlowRoute,
        ),
      ),
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
