import 'package:tawaqu3_final/models/history_trade.dart';

abstract class HistoryRepository {
  Future<List<HistoryTrade>> fetchHistory();
}
