import 'package:supabase_flutter/supabase_flutter.dart';

class PlatformRepository {
  final SupabaseClient _client;

  PlatformRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  static const List<String> supportedPlatforms = ['MT4', 'MT5'];

  Future<List<String>> getConnectedPlatforms(String userId) async {
    final res = await _client
        .from('user_platforms')
        .select('platforms:platforms!user_platforms_platform_id_fkey(name)')
        .eq('user_id', userId);

    final rows = (res as List<dynamic>);
    final out = <String>[];
    for (final r in rows) {
      if (r is! Map) continue;
      final m = Map<String, dynamic>.from(r as Map);
      final p = (m['platforms'] is Map)
          ? Map<String, dynamic>.from(m['platforms'] as Map)
          : const <String, dynamic>{};
      final name = (p['name'] ?? '').toString();
      if (name.isNotEmpty) out.add(name);
    }
    return out;
  }

  Future<void> connectPlatform({required String userId, required String platformName}) async {
    final name = platformName.toUpperCase().trim();
    if (!supportedPlatforms.contains(name)) {
      throw Exception('Unsupported platform: $platformName');
    }

    // 1) Ensure platform exists
    final platformRows = await _client
        .from('platforms')
        .select('id,name')
        .eq('name', name)
        .limit(1);

    String platformId;
    if ((platformRows as List).isNotEmpty) {
      platformId = (platformRows.first['id'] ?? '').toString();
    } else {
      final inserted = await _client
          .from('platforms')
          .insert({'name': name})
          .select('id')
          .single();
      platformId = (inserted['id'] ?? '').toString();
    }

    if (platformId.isEmpty) {
      throw Exception('Could not resolve platform id for $name');
    }

    // 2) Ensure relation exists
    final relRows = await _client
        .from('user_platforms')
        .select('id')
        .eq('user_id', userId)
        .eq('platform_id', platformId)
        .limit(1);

    if ((relRows as List).isNotEmpty) return;

    await _client.from('user_platforms').insert({
      'user_id': userId,
      'platform_id': platformId,
    });
  }

  Future<void> disconnectPlatform({required String userId, required String platformName}) async {
    final name = platformName.toUpperCase().trim();

    final platformRows = await _client
        .from('platforms')
        .select('id')
        .eq('name', name)
        .limit(1);
    if ((platformRows as List).isEmpty) return;

    final platformId = (platformRows.first['id'] ?? '').toString();
    if (platformId.isEmpty) return;

    await _client
        .from('user_platforms')
        .delete()
        .eq('user_id', userId)
        .eq('platform_id', platformId);
  }
}
