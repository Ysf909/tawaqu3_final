import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/section_title.dart';
import 'package:tawaqu3_final/view/widgets/tab_nav_bar.dart';
import '../../core/router/app_router.dart';
import '../../view_model/navigation_view_model.dart';
import '../../view_model/auth_view_model.dart';
import '../../services/api_service.dart';
import '../../models/news_item.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _api = ApiService();
  List<NewsItem> _news = [];
  Map<String, double> _prices = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final news = await _api.fetchNews();
    final prices = await _api.fetchPrices();
    if (mounted) setState(() { _news = news; _prices = prices; });
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationViewModel>();
    final auth = context.watch<AuthViewModel>();

    Widget homeTab() {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('Tawaqu3'),
            CardContainer(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Balance'),
                const SizedBox(height: 8),
                Text('\$24,580.00', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('+ \$1,245 (5.3%) this month'),
              ],
            )),
            CardContainer(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Markets'),
                const SizedBox(height: 12),
                ..._prices.entries.map((e) => ListTile(
                  title: Text(e.key),
                  trailing: Text(e.value.toStringAsFixed(2)),
                )),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () { nav.setIndex(2); }, child: const Text('Trade'))),
              ],
            )),
          ],
        ),
      );
    }

    Widget newsTab() {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('Market News'),
..._news.map((n) => CardContainer(child: ListTile(
      title: Text(n.title),
      subtitle: Text("""
${n.category} • ${n.age.inHours}h ago
${n.summary}
"""),

    ))),
          ],
        ),
      );
    }

    Widget tradeTab() {
      return Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, AppRouter.tradeFlowRoute),
          child: const Text('Open Generate Trade'),
        ),
      );
    }

    final tabs = [homeTab(), newsTab(), tradeTab()];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(onPressed: () => Navigator.pushNamed(context, AppRouter.notificationsHistoryRoute), icon: const Icon(Icons.notifications)),
          IconButton(onPressed: () => Navigator.pushNamed(context, AppRouter.settingsRoute), icon: const Icon(Icons.settings)),
          IconButton(onPressed: () { auth.logout(); Navigator.pushReplacementNamed(context, AppRouter.authRoute); }, icon: const Icon(Icons.logout)),
        ],
      ),
      body: tabs[nav.currentIndex],
      bottomNavigationBar: const TabNavBar(),
    );
  }
}

