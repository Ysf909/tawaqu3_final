import 'package:flutter/foundation.dart';

class NavigationViewModel extends ChangeNotifier {
  int currentIndex = 0; // 0: Home, 1: News, 2: Trade
  void setIndex(int i) { currentIndex = i; notifyListeners(); }
}

