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
      // 1) Create user in Supabase Auth
      final authResponse = await _client.auth.signUp(
        email: _form.email,
        password: _form.password,
      );

      final user = authResponse.user;

      if (user == null) {
        return SignupStatus.error;
      }

      // 2) Insert into your own users table
      await _client.from('users').insert({
        'id': user.id,
        'fname': _form.firstName,
        'lname': _form.lastName,
        'email': _form.email,
        'password': _form.password,       // ⚠️ SECURITY RISK — remove later
        'created_at': DateTime.now().toIso8601String(),
      });

      return SignupStatus.success;
    } on AuthException catch (e) {
      debugPrint('AuthException: ${e.message}');
      final msg = e.message.toLowerCase();

      if (msg.contains('already registered') ||
          msg.contains('already exists')) {
        return SignupStatus.emailAlreadyExists;
      }

      return SignupStatus.error;
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException: ${e.message}');
      return SignupStatus.error;
    } catch (e) {
      debugPrint('Unknown signup error: $e');
      return SignupStatus.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
