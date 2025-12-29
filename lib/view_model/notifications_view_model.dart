import 'package:flutter/foundation.dart';

class NotificationsViewModel extends ChangeNotifier {
  bool tradeAlerts = true;
  bool priceAlerts = true;
  bool newsUpdates = true;
  bool emailNotifications = false;
  bool pushNotifications = true;

  void setTradeAlerts(bool v) {
    tradeAlerts = v;
    notifyListeners();
    save();
  }

  void setPriceAlerts(bool v) {
    priceAlerts = v;
    notifyListeners();
    save();
  }

  void setNewsUpdates(bool v) {
    newsUpdates = v;
    notifyListeners();
    save();
  }

  void setEmailNotifications(bool v) {
    emailNotifications = v;
    notifyListeners();
    save();
  }

  void setPushNotifications(bool v) {
    pushNotifications = v;
    notifyListeners();
    save();
  }

  void disableAll() {
    tradeAlerts = priceAlerts = newsUpdates = emailNotifications =
        pushNotifications = false;
    notifyListeners();
    save();
  }

  void save() {
    // TODO: persist to SharedPreferences
  }
}
