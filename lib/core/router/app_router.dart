import 'package:flutter/material.dart';
import 'package:tawaqu3_final/view/pages/login_view.dart';
import 'package:tawaqu3_final/view/pages/notifications_view.dart';
import 'package:tawaqu3_final/view/pages/settings_view.dart';
import 'package:tawaqu3_final/view/pages/signup_view.dart';
import 'package:tawaqu3_final/view/pages/MainPage_view.dart';
import 'package:tawaqu3_final/view/pages/trade_flow_view.dart';
import 'package:tawaqu3_final/view/pages/menu_view.dart';
import 'package:tawaqu3_final/view/pages/history_view.dart';
import 'package:tawaqu3_final/view/pages/conects_view.dart';

class AppRouter {
  static const authRoute = '/auth';
  static const signupRoute = '/signup';
  static const MainPageRoute = '/MainPage';
  static const tradeFlowRoute = '/trade';
  static const SettingsRoute = '/settings';
  static const historyRoute = '/history';
  static const notificationsRoute = '/notifications';
  static const menuRoute = '/menu';
  static const connectsRoute = '/connects';

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
      case historyRoute:
        return MaterialPageRoute(builder: (_) => const HistoryView());
      case AppRouter.SettingsRoute:
        return MaterialPageRoute(builder: (_) => const SettingsView());
      case notificationsRoute:
        return MaterialPageRoute(builder: (_) => const NotificationsView());
      case menuRoute:
        return MaterialPageRoute(builder: (_) => const MenuView());
      case connectsRoute:
        return MaterialPageRoute(builder: (_) => const ConnectsView());
      default:
        return MaterialPageRoute(builder: (_) => const LoginView());

    }
  }
}

