import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _auth = AuthService();
  bool isLoading = false;
  String? error;

  bool get isLoggedIn => _auth.isLoggedIn;

  Future<bool> login(String email, String password) async {
    isLoading = true; error = null; notifyListeners();
    try {
      final ok = await _auth.signIn(email, password);
      return ok;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  Future<bool> signup(String email, String password) async {
    isLoading = true; error = null; notifyListeners();
    try {
      final ok = await _auth.signUp(email, password);
      return ok;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }
}

