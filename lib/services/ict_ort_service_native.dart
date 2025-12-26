import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

class IctOrtService {
  IctOrtService._();
  static final IctOrtService instance = IctOrtService._();

  OrtSession? _s1m;
  OrtSession? _s5m;

  Future<void> init() async {
    // Init ORT environment (do this once)
    OrtEnv.instance.init(); // :contentReference[oaicite:1]{index=1}

    final opts = OrtSessionOptions();
    // Faster on mobile (when available)
    opts.appendXnnpackProvider(); // :contentReference[oaicite:2]{index=2}

    _s1m = await _loadSessionFromAssets('assets/models/ict/ict_1m.onnx', opts);
    _s5m = await _loadSessionFromAssets('assets/models/ict/ict_5m.onnx', opts);

    // Debug names (helps you confirm input/output)
    // ignore: avoid_print
    print('1m inputs=${_s1m!.inputNames}, outputs=${_s1m!.outputNames}');
    // ignore: avoid_print
    print('5m inputs=${_s5m!.inputNames}, outputs=${_s5m!.outputNames}');
  }

  Future<OrtSession> _loadSessionFromAssets(String assetPath, OrtSessionOptions opts) async {
    final bd = await rootBundle.load(assetPath);
    final bytes = bd.buffer.asUint8List();
    return OrtSession.fromBuffer(bytes, opts); // :contentReference[oaicite:3]{index=3}
  }

  /// Example: input shape might be [1, 256, 7] (you must feed the shape your model expects)
  Future<Object?> predict1m(Float32List data, List<int> shape) async {
    if (_s1m == null) throw StateError('Call init() first');

    final inputName = _s1m!.inputNames.first; // usually "x"
    final inputTensor = OrtValueTensor.createTensorWithDataList(data, shape); // :contentReference[oaicite:4]{index=4}

    final runOpts = OrtRunOptions();
    final outputs = await _s1m!.runAsync(runOpts, {inputName: inputTensor});

    // IMPORTANT: free native memory
    inputTensor.release();
    runOpts.release();

    // outputs is List<OrtValue?>
    final out0 = outputs?.first;
    // out0?.value is Object? (often List/TypedList)
    return out0?.value;
  }


  Future<Object?> predict5m(Float32List data, List<int> shape) async {
    if (_s5m == null) throw StateError('Call init() first');

    final inputName = _s5m!.inputNames.first; // usually "x"
    final inputTensor = OrtValueTensor.createTensorWithDataList(data, shape);

    final runOpts = OrtRunOptions();
    final outputs = await _s5m!.runAsync(runOpts, {inputName: inputTensor});

    // IMPORTANT: free input tensor + outputs
    inputTensor.release();
    runOpts.release();

    if (outputs == null || outputs.isEmpty) return null;

    final out0 = outputs.first;
    final value = out0?.value;
    for (final o in outputs) {
      o?.release();
    }
    return value;
  }

  void dispose() {
    _s1m?.release();
    _s5m?.release();
  }
}
