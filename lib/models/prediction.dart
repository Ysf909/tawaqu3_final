class Prediction {
  final String pair;
  final double entry;
  final double sl;
  final double tp;
  final double lot;
  final int confidence;

  Prediction({
    required this.pair,
    required this.entry,
    required this.sl,
    required this.tp,
    required this.lot,
    required this.confidence,
  });
}
