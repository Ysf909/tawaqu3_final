import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tawaqu3_final/repository/history_repository.dart';
import 'package:tawaqu3_final/view_model/portfolio_view_model.dart';
import 'package:tawaqu3_final/view_model/user_session_view_model.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'view_model/auth_view_model.dart';
import 'view_model/navigation_view_model.dart';
import 'view_model/trade_view_model.dart';
import 'view_model/settings_view_model.dart';
import 'view_model/notifications_view_model.dart';
import 'view_model/history_view_model.dart';
import 'view_model/top_traders_view_model.dart';
import 'view_model/connects_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nuqjhagbndaiwswfgvfg.supabase.co',
    anonKey:
        'sb_publishable_XHoZFWS7OOsXK-IVZ6nuTA_sBokkVBg', // 👈 not service_role
  );

  runApp(const Tawaqu3App());
}

class Tawaqu3App extends StatelessWidget {
  const Tawaqu3App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => NavigationViewModel()),
        ChangeNotifierProvider(create: (_) => TradeViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationsViewModel()),
        ChangeNotifierProvider(create: (_) => HistoryViewModel(repo: HistoryRepository())),
        ChangeNotifierProvider(create: (_) => UserSessionViewModel()),
        ChangeNotifierProvider(
          create: (_) => PortfolioViewModel(baseBalance: 0),
        ),
        ChangeNotifierProvider(create: (_) => TopTradersViewModel()),
        ChangeNotifierProvider(create: (_) => ConnectsViewModel()),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Tawaqu3',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.isDark ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            onGenerateRoute: AppRouter.onGenerateRoute,
            initialRoute: AppRouter.authRoute,
          );
        },
      ),
    );
  }
}
