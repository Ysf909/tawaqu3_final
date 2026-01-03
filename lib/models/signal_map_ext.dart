extension SignalMapExt on Map<String, dynamic> {
  String get symbol => (this['symbol'] ?? '').toString();
  String get tf => (this['tf'] ?? '').toString();

  String get side =>
      (this['side'] ?? this['action'] ?? this['dir'] ?? '').toString();

  double get confidence =>
      (this['confidence'] as num?)?.toDouble() ??
      (this['score'] as num?)?.toDouble() ??
      0.0;

  double get entry => (this['entry'] as num?)?.toDouble() ?? 0.0;

  double get score => (this['score'] as num?)?.toDouble() ?? 0.0;

  String get note =>
      (this['note'] ?? this['msg'] ?? this['message'] ?? '').toString();
}
