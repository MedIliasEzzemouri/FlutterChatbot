// Stub implementation for web platforms
// This file is used when compiling for web to avoid tflite_flutter dependency

import 'dart:io';

class TFLiteHelper {
  static final List<String> _labels = [];

  static Future<bool> loadModel({
    required String modelPath,
    required String labelsPath,
  }) async {
    print('TFLite is not supported on Web.');
    return false;
  }

  static List<List<List<List<double>>>> preprocessImage(
    File imageFile,
    int inputSize,
  ) {
    throw UnsupportedError('TFLite is not supported on web');
  }

  static List<Map<String, dynamic>>? predict(File imageFile) {
    return null;
  }

  static Map<String, dynamic>? getTopPrediction(File imageFile) {
    return null;
  }

  static void dispose() {
    _labels.clear();
  }

  static bool get isLoaded => false;
}

