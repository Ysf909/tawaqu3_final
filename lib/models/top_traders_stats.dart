class TopTraderStats {
  final String userId;
  final String name;
  final String mostUsedModel;
  final String mostUsedAsset;
  final double winRate; // 0–100
  final double totalProfit; // used only for sorting, not displayed

  TopTraderStats({
    required this.userId,
    required this.name,
    required this.mostUsedModel,
    required this.mostUsedAsset,
    required this.winRate,
    required this.totalProfit,
  });
}
