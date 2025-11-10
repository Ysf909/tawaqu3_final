import 'package:flutter/foundation.dart';
import '../services/ai_service.dart';
import '../models/prediction.dart';

class TradeViewModel extends ChangeNotifier {
  final AiService _ai = AiService();

  String selectedType = 'Long';
  String selectedModel = 'ICAT';
  String selectedPair = 'XAU/USD';
  double amount = 1000;

  Prediction? lastPrediction;
  bool loading = false;

  Future<void> generate() async {
    loading = true; notifyListeners();
    lastPrediction = await _ai.predict(
      pair: selectedPair,
      type: selectedType,
      modelName: selectedModel,
      amountUSD: amount,
    );
    loading = false; notifyListeners();
  }
}

