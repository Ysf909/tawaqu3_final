import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tawaqu3_final/models/app_user.dart';
// ⛔ REMOVE this import if you have it here:
// import 'package:tawaqu3_final/view_model/user_session_view_model.dart';

enum LoginStatus {
  success,
  userNotFound,
  wrongPassword,
  error,
  emailNotConfirmed,
}

class LoginViewModel with ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 👇 NEW: keep the logged-in user here
  AppUser? _loggedInUser;
  AppUser? get loggedInUser => _loggedInUser;

  Future<LoginStatus> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Attempting login for: $email');

      final authResponse = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = authResponse.user;

      if (user == null) {
        debugPrint('Login failed: no user returned');
        return LoginStatus.error;
      }

      // OPTIONAL: you can check email confirmation here if needed

      // Fetch profile from your custom `users` table
      final profile = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        debugPrint('No profile found in users table for id: ${user.id}');
        return LoginStatus.userNotFound;
      }

      // 👇 SUCCESS CASE: store AppUser in the ViewModel
      _loggedInUser = AppUser.fromMap(profile);

      debugPrint('Login success for: $email');
      return LoginStatus.success;
    } on AuthException catch (e) {
      debugPrint('AuthException (login): ${e.message}');
      final msg = e.message.toLowerCase();

      if (msg.contains('invalid login credentials')) {
        return LoginStatus.wrongPassword;
      }
      if (msg.contains('not found')) {
        return LoginStatus.userNotFound;
      }
      if (msg.contains('confirm') || msg.contains('email not confirmed')) {
        return LoginStatus.emailNotConfirmed;
      }
      return LoginStatus.error;
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException (login profile): ${e.message}');
      return LoginStatus.error;
    } catch (e) {
      debugPrint('Unknown login error: $e');
      return LoginStatus.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
