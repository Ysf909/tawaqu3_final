import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tawaqu3_final/services/auth_service.dart';

enum LoginStatus { success, userNotFound, wrongPassword, error }

enum SignupStatus { success, emailAlreadyExists, error }

class AuthViewModel with ChangeNotifier {
  final AuthService _authService;

  AuthViewModel({AuthService? authService})
    : _authService = authService ?? AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<LoginStatus> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return LoginStatus.success;
      }

      return LoginStatus.error;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        // can be wrong email or password – we’ll treat as wrongPassword
        return LoginStatus.wrongPassword;
      }
      if (msg.contains('not found') || msg.contains('email not confirmed')) {
        return LoginStatus.userNotFound;
      }
      return LoginStatus.error;
    } catch (_) {
      return LoginStatus.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SignupStatus> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      if (response.user != null) {
        return SignupStatus.success;
      }

      return SignupStatus.error;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') ||
          msg.contains('already exists')) {
        return SignupStatus.emailAlreadyExists;
      }
      return SignupStatus.error;
    } catch (_) {
      return SignupStatus.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() => _authService.signOut();
}
