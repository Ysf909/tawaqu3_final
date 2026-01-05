import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Web version: inference happens in FastAPI (Python onnxruntime),
/// because Flutter Web can't use ffi/onnxruntime.
///
class SmcOrtService {
  SmcOrtService._();
  static final SmcOrtService instance = SmcOrtService._();

  bool _ready = false;
  bool get isReady => _ready;

  // If you run server elsewhere, change this:
  final String _predictUrl = 'http://127.0.0.1:8000/predict';

  Future<void> init() async {
    _ready = true;
  }

  Future<Object?> predict15m(Float32List x, List<int> shape) async {
    if (!_ready) await init();
    return _predict(tf: '15m', x: x, shape: shape);
  }

  Future<Object?> predict30m(Float32List x, List<int> shape) async {
    if (!_ready) await init();
    return _predict(tf: '30m', x: x, shape: shape);
  }

  Future<Object?> _predict({
    required String tf,
    required Float32List x,
    required List<int> shape,
  }) async {
    final body = <String, dynamic>{
      'model': 'smc',
      'tf': tf,
      'shape': shape,
      'features': x.toList(), // 300 floats
    };

    final resp = await http.post(
      Uri.parse(_predictUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200)
      throw Exception('Predict failed (${resp.statusCode}): ${resp.body}');

    final j = jsonDecode(resp.body) as Map<String, dynamic>;

    // Prefer returning "out" list to match your existing parsing pipeline
    final outAny =
        j['out'] ??
        (j['outputs'] is List && (j['outputs'] as List).isNotEmpty
            ? (j['outputs'] as List).first
            : null);

    return outAny;
  }
}
