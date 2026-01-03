import 'package:flutter/foundation.dart';

import '../models/top_traders_stats.dart';
import '../repository/top_traders_repository.dart';

class TopTradersViewModel extends ChangeNotifier {
  final TopTradersRepository _repo;

  TopTradersViewModel({TopTradersRepository? repo})
    : _repo = repo ?? TopTradersRepository();

  bool loading = false;
  String? error;
  List<TopTraderStats> traders = const [];

  Future<void> load({int limit = 20}) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      traders = await _repo.fetchTopTraders(limit: limit);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
