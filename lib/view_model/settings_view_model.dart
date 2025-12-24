import 'package:flutter/foundation.dart';

class SettingsViewModel extends ChangeNotifier {
  bool isDark = true;
  String language = 'English';
  bool mt5Connected = true;

  void toggleTheme() { isDark = !isDark; notifyListeners(); }
  void setLanguage(String lang) { language = lang; notifyListeners(); }
  void setMt5(bool value) { mt5Connected = value; notifyListeners(); }
}

