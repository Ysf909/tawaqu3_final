class TopTrader {
  final String userId;
  final String name;
  final double winRate;
  final String mostUsedModel;
  final String mostUsedAsset;
  final double? totalProfit; // ✅ nullable
  final bool isProfitHidden;

  TopTrader({
    required this.userId,
    required this.name,
    required this.totalProfit,
    required this.winRate,
    required this.mostUsedModel,
    required this.mostUsedAsset,
    required this.isProfitHidden,
  });

  factory TopTrader.fromJson(Map<String, dynamic> json) {
    return TopTrader(
      userId: (json['user_id'] ?? '').toString(),
      name: (json['name'] ?? 'Trader').toString(),
      winRate: (json['win_rate'] as num?)?.toDouble() ?? 0.0,
      mostUsedModel: (json['most_used_model'] ?? '').toString(),
      mostUsedAsset: (json['most_used_asset'] ?? '').toString(),
      totalProfit: (json['total_profit'] as num?)?.toDouble(), // ✅ can be null
      isProfitHidden: (json['is_profit_hidden'] as bool?) ?? false,
    );
  }
}
