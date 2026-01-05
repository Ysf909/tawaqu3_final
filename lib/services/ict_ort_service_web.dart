import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Web (Chrome) implementation: calls Python ONNX server
class IctOrtService {
  IctOrtService._();
  static final IctOrtService instance = IctOrtService._();

  /// Python server on same PC
  String baseUrl = 'http://127.0.0.1:8000';

  Future<void> init() async {}

  Future<Object?> predict1m(Float32List data, List<int> shape) async {
    return _predict(tf: '1m', data: data);
  }

  Future<Object?> predict5m(Float32List data, List<int> shape) async {
    return _predict(tf: '5m', data: data);
  }

  Future<List<double>> _predict({
    required String tf,
    required Float32List data,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'tf': tf, 'features': data.toList()}),
    );

    if (res.statusCode != 200) {
      throw Exception('Predict server error ${res.statusCode}: ${res.body}');
    }

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final dynamic outAny =
        j['out'] ??
        (j['outputs'] is List && (j['outputs'] as List).isNotEmpty
            ? (j['outputs'] as List).first
            : null);

    final raw = outAny as List?;
    final out = (raw ?? const [])
        .whereType<num>()
        .map((e) => e.toDouble())
        .toList();

    // fallback: if server returns only score/side, keep pipeline alive
    if (out.isEmpty && (j['score'] is num)) {
      final s = (j['score'] as num).toDouble();
      final side = (j['side'] ?? '').toString().toUpperCase();
      if (side == 'SELL') return <double>[s, 0.0];
      if (side == 'BUY') return <double>[0.0, s];
      return <double>[s];
    }

    return out;
  }

  void dispose() {}
}
