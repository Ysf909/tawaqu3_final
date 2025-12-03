import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tawaqu3_final/models/signup_model.dart';

enum SignupStatus { success, emailAlreadyExists, error }

class SignupViewModel with ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  SignupModel _form = const SignupModel();
  SignupModel get form => _form;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void updateFirstName(String value) {
    _form = _form.copyWith(firstName: value);
  }

  void updateLastName(String value) {
    _form = _form.copyWith(lastName: value);
  }

  void updateEmail(String value) {
    _form = _form.copyWith(email: value);
  }

  void updatePassword(String value) {
    _form = _form.copyWith(password: value);
  }

  Future<SignupStatus> signup() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _client.auth.signUp(
        email: _form.email,
        password: _form.password,
        data: {
          'first_name': _form.firstName,
          'last_name': _form.lastName,
        },
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
}
