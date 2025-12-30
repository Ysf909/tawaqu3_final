import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class SocialAuthService {
  SocialAuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // ✅ Put your real IDs here
  // Web Client ID (from Google Cloud OAuth Client)
  static const String googleWebClientId = '6623679332-jbshilvl8gj5obprsj6ne4q8jsbdfmp9.apps.googleusercontent.com';

  // iOS Client ID (from Google Cloud OAuth Client for iOS)
  // If you don't have iOS yet, keep it empty for now, but GoogleSignIn on iOS needs it.
  static const String googleIosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

  /// Returns AuthResponse if success, null if user cancelled.
  Future<AuthResponse?> signInWithGoogle() async {
  final googleSignIn = GoogleSignIn(
    serverClientId: googleWebClientId, // ✅ WEB client id
  );

  final googleUser = await googleSignIn.signIn();
  if (googleUser == null) return null;

  final googleAuth = await googleUser.authentication;
  final accessToken = googleAuth.accessToken;
  final idToken = googleAuth.idToken;

  if (accessToken == null) throw const AuthException('No Access Token found.');
  if (idToken == null) throw const AuthException('No ID Token found.');

  return _client.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: idToken,
    accessToken: accessToken, // required for Google :contentReference[oaicite:3]{index=3}
  );
}


  /// Returns AuthResponse if success, null if user cancelled.
  Future<AuthResponse?> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login(
      permissions: const ['public_profile', 'email'],
    );

    if (result.status == LoginStatus.cancelled) return null;

    if (result.status != LoginStatus.success) {
      throw AuthException('Facebook login failed: ${result.status}');
    }

    final accessToken = result.accessToken?.tokenString;
    if (accessToken == null) {
      throw const AuthException('No Facebook access token found.');
    }

    // Supabase native Facebook sign-in (token goes into idToken)
    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.facebook,
      idToken: accessToken,
    );
  }
}
