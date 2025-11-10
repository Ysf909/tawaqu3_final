import '../models/news_item.dart';

class ApiService {
  Future<List<NewsItem>> fetchNews() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      NewsItem('Gold prices surge amid uncertainty', 'Markets', 'XAU/USD spikes...', const Duration(hours: 2)),
      NewsItem('BTC breaks resistance', 'Crypto', 'Momentum continues...', const Duration(hours: 6)),
      NewsItem('ECB holds rates', 'Economics', 'Mixed outlook...', const Duration(hours: 9)),
    ];
  }

  Future<Map<String, double>> fetchPrices() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'XAU/USD': 2045.30,
      'EUR/USD': 1.0856,
      'BTC/USD': 43250.00,
      'ETH/USD': 2315.50,
    };
  }
}

