import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tawaqu3_final/models/login_model.dart';

enum LoginStatus { success, userNotFound, wrongPassword, error }

class LoginViewModel with ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  LoginModel _form = const LoginModel();
  LoginModel get form => _form;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void updateEmail(String email) {
    _form = _form.copyWith(email: email);
  }

  void updatePassword(String password) {
    _form = _form.copyWith(password: password);
  }

  Future<LoginStatus> login() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _client.auth.signInWithPassword(
        email: _form.email,
        password: _form.password,
      );

      if (response.user != null) {
        return LoginStatus.success;
      }

      return LoginStatus.error;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        // Supabase does not tell you if email or password is wrong
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
}
