import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:onnxruntime/onnxruntime.dart';

class SmcOrtService {
  SmcOrtService._();
  static final SmcOrtService instance = SmcOrtService._();

  OrtSession? _s15m;
  OrtSession? _s30m;

  bool _ready = false;
  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;

    try {
      OrtEnv.instance.init();
    } catch (_) {}

    final opts = OrtSessionOptions();
    _s15m = await _loadSession('assets/models/smc/smc_15m.onnx', opts);
    _s30m = await _loadSession('assets/models/smc/smc_30m.onnx', opts);

    _ready = true;
  }

  Future<OrtSession> _loadSession(
    String assetPath,
    OrtSessionOptions opts,
  ) async {
    final bytes = (await rootBundle.load(assetPath)).buffer.asUint8List();
    return OrtSession.fromBuffer(bytes, opts);
  }

  Future<Object?> predict15m(Float32List x, List<int> shape) async {
    if (!_ready || _s15m == null) throw Exception('SMC 15m model not ready');
    return _run(_s15m!, x, shape);
  }

  Future<Object?> predict30m(Float32List x, List<int> shape) async {
    if (!_ready || _s30m == null) throw Exception('SMC 30m model not ready');
    return _run(_s30m!, x, shape);
  }

  Future<Object?> _run(
    OrtSession session,
    Float32List x,
    List<int> shape,
  ) async {
    final inputName = session.inputNames.isNotEmpty
        ? session.inputNames.first
        : 'x';
    final outNames = session.outputNames.isNotEmpty
        ? <String>[session.outputNames.first]
        : null;

    final inputTensor = OrtValueTensor.createTensorWithDataList(x, shape);
    final runOptions = OrtRunOptions();

    try {
      final outs = session.run(runOptions, {inputName: inputTensor}, outNames);
      final out0 = (outs.isNotEmpty) ? outs.first?.value : null;
      for (final o in outs) {
        o?.release();
      }
      return out0;
    } finally {
      inputTensor.release();
      runOptions.release();
    }
  }
}
