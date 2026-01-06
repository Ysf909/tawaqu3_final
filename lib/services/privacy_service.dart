import 'package:supabase_flutter/supabase_flutter.dart';

class PrivacyService {
  final SupabaseClient _db;

  PrivacyService({SupabaseClient? client}) : _db = client ?? Supabase.instance.client;

  Future<bool> getHideProfit() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception("Not logged in");

    final data = await _db
        .from('users') // ✅ changed
        .select('hide_profit')
        .eq('id', uid) // ✅ assumes users.id is the auth uid
        .single();

    return (data['hide_profit'] as bool?) ?? false;
  }

  Future<void> setHideProfit(bool value) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception("Not logged in");

    await _db
        .from('users') // ✅ changed
        .update({'hide_profit': value})
        .eq('id', uid);
  }
}
