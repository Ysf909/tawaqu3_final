import 'package:flutter/material.dart';
import '../services/privacy_service.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({PrivacyService? privacyService})
      : _privacyService = privacyService ?? PrivacyService() {
    // ignore: discarded_futures
    loadPrivacy();
  }

  final PrivacyService _privacyService;

  // ===== Your existing fields =====
  bool isDark = false;
  String language = 'English';

  void toggleTheme() {
    isDark = !isDark;
    notifyListeners();
    // TODO: persist theme (SharedPreferences) if you already do
  }

  void setLanguage(String v) {
    language = v;
    notifyListeners();
    // TODO: persist language if you already do
  }

  // ===== Privacy (NEW) =====
  bool hideProfit = false;
  bool privacyLoading = false;
  String? privacyError;

  Future<void> loadPrivacy() async {
    privacyLoading = true;
    privacyError = null;
    notifyListeners();

    try {
      hideProfit = await _privacyService.getHideProfit();
    } catch (e) {
      privacyError = e.toString();
    } finally {
      privacyLoading = false;
      notifyListeners();
    }
  }

  Future<void> setHideProfit(bool value) async {
    final old = hideProfit;

    // optimistic UI
    hideProfit = value;
    privacyLoading = true;
    privacyError = null;
    notifyListeners();

    try {
      await _privacyService.setHideProfit(value);
    } catch (e) {
      // rollback if failed
      hideProfit = old;
      privacyError = e.toString();
    } finally {
      privacyLoading = false;
      notifyListeners();
    }
  }
}
