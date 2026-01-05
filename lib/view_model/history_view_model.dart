import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tawaqu3_final/models/history_trade.dart';
import 'package:tawaqu3_final/repository/history_repository.dart';

enum HistorySort { newest, oldest, entryHigh, entryLow }

abstract class HistoryListItem {}

class HistoryDayHeader extends HistoryListItem {
  final String day; // yyyy-mm-dd
  HistoryDayHeader(this.day);
}

class HistoryTradeItem extends HistoryListItem {
  final HistoryTrade trade;
  HistoryTradeItem(this.trade);
}

class HistoryViewModel extends ChangeNotifier {
  final HistoryRepository _repo;

  HistoryViewModel({required HistoryRepository repo}) : _repo = repo;

  bool _loading = false;
  String? _error;
  List<HistoryTrade> _trades = [];

  String _query = '';
  HistorySort _sort = HistorySort.newest;
  bool _groupByDay = true;

  bool get loading => _loading;
  String? get error => _error;

  HistorySort get sort => _sort;
  bool get groupByDay => _groupByDay;

  int get totalTrades => _filteredSorted().length;

  Future<void> loadHistory() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) {
        _trades = [];
        _error = 'User not logged in.';
        return;
      }
      _trades = await _repo.getHistoryForUser(uid);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setQuery(String v) {
    _query = v;
    notifyListeners();
  }

  void setSort(HistorySort v) {
    _sort = v;
    notifyListeners();
  }

  void toggleGroupByDay() {
    _groupByDay = !_groupByDay;
    notifyListeners();
  }

  List<HistoryListItem> get items {
    final list = _filteredSorted();
    if (!_groupByDay) return list.map((t) => HistoryTradeItem(t)).toList();

    final out = <HistoryListItem>[];
    String? lastDay;

    for (final t in list) {
      final day = _formatDay(t.dateSaved.toLocal());
      if (day != lastDay) {
        out.add(HistoryDayHeader(day));
        lastDay = day;
      }
      out.add(HistoryTradeItem(t));
    }
    return out;
  }

  List<HistoryTrade> _filteredSorted() {
    final q = _query.trim().toLowerCase();

    final filtered = _trades.where((t) {
      if (q.isEmpty) return true;

      final entry = (t.previousEntry?.toString() ?? '').toLowerCase();
      final sl = (t.previousSl?.toString() ?? '').toLowerCase();
      final tp = (t.previousTp?.toString() ?? '').toLowerCase();
      final lot = (t.previousLot?.toString() ?? '').toLowerCase();
      final name = ('${t.fname} ${t.lname}').toLowerCase();
      final day = _formatDay(t.dateSaved.toLocal()).toLowerCase();

      return entry.contains(q) ||
          sl.contains(q) ||
          tp.contains(q) ||
          lot.contains(q) ||
          name.contains(q) ||
          day.contains(q);
    }).toList();

    int cmp(HistoryTrade a, HistoryTrade b) {
      switch (_sort) {
        case HistorySort.newest:
          return b.dateSaved.compareTo(a.dateSaved);
        case HistorySort.oldest:
          return a.dateSaved.compareTo(b.dateSaved);
        case HistorySort.entryHigh:
          return (b.previousEntry ?? 0).compareTo(a.previousEntry ?? 0);
        case HistorySort.entryLow:
          return (a.previousEntry ?? 0).compareTo(b.previousEntry ?? 0);
      }
    }

    filtered.sort(cmp);
    return filtered;
  }

  String _formatDay(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final da = d.day.toString().padLeft(2, '0');
    return '$y-$m-$da';
  }
}
