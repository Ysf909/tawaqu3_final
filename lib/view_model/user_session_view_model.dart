import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

class UserSessionViewModel extends ChangeNotifier {
  AppUser? _user;

  AppUser? get user => _user;

  String get fullName => _user?.fullName ?? 'Guest';
  String get initials {
    if (_user == null) return '?';
    final name = _user!.fullName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    final first = parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    final second = parts[1].isNotEmpty ? parts[1][0].toUpperCase() : '';
    return '$first$second';
  }

  void setUser(AppUser user) {
    _user = user;
    debugPrint('UserSessionViewModel.setUser -> ${user.fullName}'); 
    notifyListeners();
  }

  void clear() {
    _user = null;
    notifyListeners();
  }
}
