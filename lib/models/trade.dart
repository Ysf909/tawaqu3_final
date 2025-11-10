class Trade {
  final String pair;
  final String direction; // 'Long' or 'Short' or 'Scalper'
  final double entry;
  final double stopLoss;
  final double takeProfit;
  final double lot;
  final DateTime createdAt;
  final double? profit;

  Trade({
    required this.pair,
    required this.direction,
    required this.entry,
    required this.stopLoss,
    required this.takeProfit,
    required this.lot,
    required this.createdAt,
    this.profit,
  });
}

