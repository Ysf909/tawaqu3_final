import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _goldBaseUrl = "https://www.goldapi.io/api";
  static const String _goldApiKey = "goldapi-hplxsmishxt7i-io";

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
          "https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd");
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
          "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd");
      print("Calling CoinGecko BTC: $uri");

      final res = await http.get(uri);
      print("BTC status: ${res.statusCode}");
      print("BTC body: ${res.body}");

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

 Future<double?> fetchEurUsd() async {
  try {
    final uri = Uri.parse("https://open.er-api.com/v6/latest/EUR");
    print("Calling FX EUR/USD: $uri");

    final res = await http.get(uri);
    print("FX status: ${res.statusCode}");
    print("FX body: ${res.body}");

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      // structure: { "rates": { "USD": 1.08, ... }, "base_code": "EUR", ... }
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
    final gold = await fetchGoldUsd();
    final eth = await fetchEthUsd();
    final eur = await fetchEurUsd();
    final btc = await fetchBtcUsd();

    return {
      "XAU/USD": gold ?? 0.0,
      "BTC/USD": btc ?? 0.0,
      "ETH/USD": eth ?? 0.0,
      "EUR/USD": eur ?? 0.0,
    };
  }
}
