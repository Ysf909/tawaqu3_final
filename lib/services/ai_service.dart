import 'dart:math';
import '../models/prediction.dart';

class AiService {
  final _rng = Random();

  Future<Prediction> predict({
    required String pair,
    required String type, // Long | Short | Scalper
    required String modelName, // ICAT | 3M | etc.
    required double amountUSD,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Fake values near price 2000 for demo
    final base = 2045.30;
    final entry = base + (_rng.nextDouble() * 4 - 2);
    final sl = entry - (_rng.nextDouble() * 10 + 2);
    final tp = entry + (_rng.nextDouble() * 15 + 2);
    final lot = double.parse((amountUSD / 2000).toStringAsFixed(2));
    final conf = 80 + _rng.nextInt(19);
    return Prediction(
      pair: pair,
      entry: entry,
      sl: sl,
      tp: tp,
      lot: lot,
      confidence: conf,
    );
  }
}
