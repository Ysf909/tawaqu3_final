import 'package:flutter/material.dart';
import 'package:tawaqu3_final/view/pages/login_view.dart';
import 'package:tawaqu3_final/view/pages/signup_view.dart';
import 'package:tawaqu3_final/view/pages/MainPage_view.dart';
import 'package:tawaqu3_final/view/pages/trade_flow_view.dart';
import 'package:tawaqu3_final/view/pages/settings_view.dart';
import 'package:tawaqu3_final/view/pages/notifications_history_view.dart';

class AppRouter {
  static const authRoute = '/auth';
  static const signupRoute = '/signup';
  static const MainPageRoute = '/MainPage';
  static const tradeFlowRoute = '/trade';
  static const settingsRoute = '/settings';
  static const notificationsHistoryRoute = '/noti-history';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case authRoute:
        return MaterialPageRoute(builder: (_) => const LoginView());
      case signupRoute:
        return MaterialPageRoute(builder: (_) => const SignupView());
      case MainPageRoute:
        return MaterialPageRoute(builder: (_) => const MainPage());
      case tradeFlowRoute:
        return MaterialPageRoute(builder: (_) => const TradeFlowView());
      case notificationsHistoryRoute:
        return MaterialPageRoute(builder: (_) => const NotificationsHistoryView());
      case AppRouter.settingsRoute:
        return MaterialPageRoute(builder: (_) => const SettingsView());
      default:
        return MaterialPageRoute(builder: (_) => const LoginView());
    }
  }
}

