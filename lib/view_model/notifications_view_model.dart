import 'package:flutter/foundation.dart';

class NotificationsViewModel extends ChangeNotifier {
  bool tradeAlerts = true;
  bool priceAlerts = true;
  bool newsUpdates = true;
  bool emailNotifications = false;
  bool pushNotifications = true;

  void disableAll() {
    tradeAlerts = priceAlerts = newsUpdates = emailNotifications =
        pushNotifications = false;
    notifyListeners();
  }

  void save() {
    /* TODO: persist to SharedPreferences */
  }
}
