import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repository/platform_repository.dart';

class ConnectsViewModel extends ChangeNotifier {
  final PlatformRepository _repo;
  final SupabaseClient _client;

  ConnectsViewModel({PlatformRepository? repo, SupabaseClient? client})
    : _repo = repo ?? PlatformRepository(),
      _client = client ?? Supabase.instance.client;

  bool loading = false;
  String? error;
  List<String> connected = const [];

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<void> load() async {
    final uid = currentUserId;
    if (uid == null) {
      connected = const [];
      notifyListeners();
      return;
    }

    loading = true;
    error = null;
    notifyListeners();
    try {
      connected = await _repo.getConnectedPlatforms(uid);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> connect(String platformName) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');
    await _repo.connectPlatform(userId: uid, platformName: platformName);
    await load();
  }

  Future<void> disconnect(String platformName) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');
    await _repo.disconnectPlatform(userId: uid, platformName: platformName);
    await load();
  }
}
