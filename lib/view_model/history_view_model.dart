import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/history_trade.dart';
import '../repository/history_repository.dart';

class HistoryViewModel extends ChangeNotifier {
  final HistoryRepository _historyRepo = HistoryRepository();
  final SupabaseClient _client = Supabase.instance.client;

  HistoryViewModel();

  List<HistoryTrade> _trades = [];
  List<HistoryTrade> get trades => _trades;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<void> loadHistory() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        _trades = [];
        _loading = false;
        notifyListeners();
        return;
      }

      final userId = user.id;
      _trades = await _historyRepo.getHistoryForUser(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadHistory();
}
