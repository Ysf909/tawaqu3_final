import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'view_model/auth_view_model.dart';
import 'view_model/navigation_view_model.dart';
import 'view_model/trade_view_model.dart';
import 'view_model/settings_view_model.dart';
import 'view_model/notifications_view_model.dart';
import 'view_model/history_view_model.dart';

void main() {
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
        ChangeNotifierProvider(create: (_) => HistoryViewModel()),
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

