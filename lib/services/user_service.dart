import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tawaqu3_final/models/app_user.dart';

class UserService {
  UserService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<AppUser> ensureUserRow({required String provider}) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null)
      throw const AuthException('No authenticated user found.');

    final email = authUser.email;
    if (email == null || email.isEmpty) {
      throw const AuthException('Provider did not return an email.');
    }

    final meta = authUser.userMetadata ?? {};
    final fullName = (meta['full_name'] ?? meta['name'] ?? '')
        .toString()
        .trim();

    String fname = (meta['given_name'] ?? '').toString().trim();
    String lname = (meta['family_name'] ?? '').toString().trim();

    if (fname.isEmpty && lname.isEmpty && fullName.isNotEmpty) {
      final parts = fullName
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
      fname = parts.isNotEmpty ? parts.first : 'User';
      lname = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }
    if (fname.isEmpty) fname = 'User';

    final row = await _client
        .from('users')
        .upsert({
          'email': email,
          'fname': fname,
          'lname': lname,
          'auth_provider': provider,
          'auth_uid': authUser.id,
        }, onConflict: 'email')
        .select()
        .single();

    return AppUser.fromMap(row);
  }
}
