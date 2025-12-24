import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tawaqu3_final/models/news_item.dart';


class MarketPrice {
  final double price;
  final double? change24h; // percent over last 24h, can be null

  const MarketPrice({
    required this.price,
    this.change24h,
  });
}

class ApiService {
  // ---------- PRICES (your existing code) ----------
  static const String _goldBaseUrl = "https://www.goldapi.io/api";
  static const String _goldApiKey = "goldapi-hplxsmishxt7i-io";

  static const String _newsApiKey =
      "pub_a5faafb0098f4512b7106e9d4207dc49"; // 👈 reuse for all news

  Map<String, String> get _goldHeaders => {
        "x-access-token": _goldApiKey,
        "Content-Type": "application/json",
      };

  Future<double?> fetchGoldUsd() async {
    try {
      final uri = Uri.parse("$_goldBaseUrl/XAU/USD");
      print("Calling GoldAPI: $uri");

      final res = await http.get(uri, headers: _goldHeaders);

      print("GoldAPI status: ${res.statusCode}");
      print("GoldAPI body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final price = data["price"];
        if (price == null) {
          print("GoldAPI: price field is null");
          return null;
        }
        return (price as num).toDouble();
      } else {
        return null;
      }
    } catch (e) {
      print("GoldAPI exception: $e");
      return null;
    }
  }

  Future<double?> fetchEthUsd() async {
    try {
      final uri = Uri.parse(
        "https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd",
      );
      print("Calling CoinGecko ETH: $uri");

      final res = await http.get(uri);
      print("ETH status: ${res.statusCode}");
      print("ETH body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final price = data["ethereum"]["usd"];
        return (price as num).toDouble();
      } else {
        return null;
      }
    } catch (e) {
      print("ETH exception: $e");
      return null;
    }
  }

  Future<double?> fetchBtcUsd() async {
    try {
      final uri = Uri.parse(
        "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd",
      );
      print("Calling CoinGecko BTC: $uri");

      final res = await http.get(uri);
      print("BTC status: ${res.statusCode}");
      print("BTC body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final price = data["bitcoin"]["usd"];
        return (price as num).toDouble();
      } else {
        return null;
      }
    } catch (e) {
      print("BTC exception: $e");
      return null;
    }
  }

  Future<double?> fetchEurUsd() async {
    try {
      final uri = Uri.parse("https://open.er-api.com/v6/latest/EUR");
      print("Calling FX EUR/USD: $uri");

      final res = await http.get(uri);
      print("FX status: ${res.statusCode}");
      print("FX body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final price = data["rates"]["USD"];
        return (price as num).toDouble();
      } else {
        return null;
      }
    } catch (e) {
      print("FX exception: $e");
      return null;
    }
  }

  Future<Map<String, double>> fetchAllOnce() async {
  // Prices come from your WebSocket tick server (MT5 -> Node -> Flutter).
  // Placeholders only (WebSocket will overwrite).
  return {
    "XAUUSD_": 0.0,
    "EURUSD_": 0.0,
    "BTCUSD": 0.0,
    "ETHUSD": 0.0,
  };
}

  // ---------- CRYPTO NEWS (NewsData crypto endpoint) ----------
  // ---------- CRYPTO ----------
  static const String _cryptoNewsUrl =
      "https://newsdata.io/api/1/crypto?apikey=pub_a5faafb0098f4512b7106e9d4207dc49";

  Future<List<NewsItem>> fetchCryptoNews() async {
    try {
      final uri = Uri.parse(_cryptoNewsUrl);
      print("Calling NewsData crypto: $uri");

      final res = await http.get(uri);
      print("Crypto news status: ${res.statusCode}");
      // print("Crypto news body: ${res.body}");

      if (res.statusCode != 200) return [];

      final data = json.decode(res.body);
      final List results = data["results"] ?? [];

      final now = DateTime.now().toUtc();

      return results.map<NewsItem>((item) {
        final title = item["title"] ?? "No title";
        final summary = item["description"] ?? "";
        final pubDateStr = item["pubDate"] ?? "";
        Duration age = Duration.zero;
        DateTime? publishedAt;

        try {
          final normalized = pubDateStr.replaceFirst(' ', 'T');
          final pub = DateTime.parse(normalized).toUtc();
           publishedAt = pub;
          age = now.difference(pub);
        } catch (_) {}

        return NewsItem(
          title: title,
          category: "Crypto",
          summary: summary.isNotEmpty ? summary : (item["source_id"] ?? ""),
          age: age,
          publishedAt: publishedAt,
        );
      }).toList();
    } catch (e) {
      print("Crypto news exception: $e");
      return [];
    }
  }

  // ---------- FOREX ----------
  Future<List<NewsItem>> fetchForexNews() async {
    try {
      final uri = Uri.parse(
        "https://newsdata.io/api/1/news"
        "?apikey=$_newsApiKey"
        "&q=forex OR EURUSD OR GBPUSD OR USDJPY"
        "&language=en",
      );
      print("Calling NewsData forex: $uri");

      final res = await http.get(uri);
      print("Forex news status: ${res.statusCode}");
      // print("Forex news body: ${res.body}");

      if (res.statusCode != 200) return [];

      final data = json.decode(res.body);
      final List results = data["results"] ?? [];

      final now = DateTime.now().toUtc();

      return results.map<NewsItem>((item) {
        final title = item["title"] ?? "No title";
        final summary = item["description"] ?? "";
        final pubDateStr = item["pubDate"] ?? "";
        Duration age = Duration.zero;
        DateTime? publishedAt;

        try {
          final normalized = pubDateStr.replaceFirst(' ', 'T');
          final pub = DateTime.parse(normalized).toUtc();
          publishedAt = pub;
          age = now.difference(pub);
        } catch (_) {}

        return NewsItem(
          title: title,
          category: "Forex",
          summary: summary.isNotEmpty ? summary : (item["source_id"] ?? ""),
          age: age,
          publishedAt: publishedAt,
        );
      }).toList();
    } catch (e) {
      print("Forex news exception: $e");
      return [];
    }
  }

  // ---------- METALS ----------
  Future<List<NewsItem>> fetchMetalsNews() async {
    try {
      final uri = Uri.parse(
        "https://newsdata.io/api/1/news"
        "?apikey=$_newsApiKey"
        "&q=gold OR silver OR XAUUSD OR precious%20metals"
        "&language=en",
      );
      print("Calling NewsData metals: $uri");

      final res = await http.get(uri);
      print("Metals news status: ${res.statusCode}");
      // print("Metals news body: ${res.body}");

      if (res.statusCode != 200) return [];

      final data = json.decode(res.body);
      final List results = data["results"] ?? [];

      final now = DateTime.now().toUtc();

      return results.map<NewsItem>((item) {
        final title = item["title"] ?? "No title";
        final summary = item["description"] ?? "";
        final pubDateStr = item["pubDate"] ?? "";
        Duration age = Duration.zero;
        DateTime? publishedAt;

        try {
          final normalized = pubDateStr.replaceFirst(' ', 'T');
          final pub = DateTime.parse(normalized).toUtc();
          publishedAt = pub;
          age = now.difference(pub);
        } catch (_) {}

        return NewsItem(
          title: title,
          category: "Metals",
          summary: summary.isNotEmpty ? summary : (item["source_id"] ?? ""),
          publishedAt: publishedAt,
          age: age,
        );
      }).toList();
    } catch (e) {
      print("Metals news exception: $e");
      return [];
    }
  }

  // ---------- COMBINED (ALL) ----------
  Future<List<NewsItem>> fetchAllNews() async {
    final crypto = await fetchCryptoNews();
    final forex = await fetchForexNews();
    final metals = await fetchMetalsNews();

    final all = [...crypto, ...forex, ...metals];

    // sort newest first (smaller age = newer)
    all.sort((a, b) => a.age.compareTo(b.age));

    return all;
  }
}


