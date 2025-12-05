import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum LoginStatus { success, userNotFound, wrongPassword, error, emailNotConfirmed }

class LoginViewModel with ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<LoginStatus> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Attempting login for: $email'); // 👀 debug

      final authResponse = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = authResponse.user;

      if (user == null) {
        debugPrint('Login failed: no user returned');
        return LoginStatus.error;
      }

      // OPTIONAL: check your "users" table
      final profile = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        debugPrint('No profile found in users table for id: ${user.id}');
        return LoginStatus.userNotFound;
      }

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
