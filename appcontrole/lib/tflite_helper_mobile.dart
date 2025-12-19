// Mobile implementation with actual TFLite support
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteHelper {
  static Interpreter? _interpreter;
  static List<String> _labels = [];
  static bool _isLoaded = false;

  // Initialize (stub for mobile - no initialization needed)
  static Future<void> initialize() async {
    // Mobile doesn't need initialization, models load directly
    return;
  }

  // Load model and labels using TFLite API
  static Future<bool> loadModel({
    required String modelPath,
    required String labelsPath,
  }) async {
    try {
      // Load labels from assets
      final labelData = await rootBundle.loadString(labelsPath);
      _labels = labelData.split('\n').where((label) => label.trim().isNotEmpty).toList();
      print('Loaded ${_labels.length} labels: $_labels');

      // Load TFLite model using Interpreter.fromAsset API
      _interpreter = await Interpreter.fromAsset(modelPath);
      
      // Get model information
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();
      
      print('Model loaded successfully');
      print('Input tensors: ${inputTensors.length}');
      print('Output tensors: ${outputTensors.length}');
      
      if (inputTensors.isNotEmpty) {
        print('Input tensor shape: ${inputTensors[0].shape}');
        print('Input tensor type: ${inputTensors[0].type}');
      }
      
      if (outputTensors.isNotEmpty) {
        print('Output tensor shape: ${outputTensors[0].shape}');
        print('Output tensor type: ${outputTensors[0].type}');
      }
      
      _isLoaded = true;
      return true;
    } catch (e) {
      print('Error loading TFLite model: $e');
      print('Model path: $modelPath');
      print('Stack trace: ${StackTrace.current}');
      _isLoaded = false;
      return false;
    }
  }

  // Preprocess image for model input
  static List<List<List<List<double>>>> preprocessImage(
    File imageFile,
    int inputSize,
  ) {
    final imageBytes = imageFile.readAsBytesSync();
    final image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Could not decode image');
    }

    // Resize image to model input size
    final resizedImage = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
    );

    // Convert to float array and normalize (0-1)
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (_) => List.generate(
          inputSize,
          (_) => List.generate(3, (_) => 0.0),
        ),
      ),
    );

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resizedImage.getPixel(x, y);
        input[0][y][x][0] = pixel.r / 255.0; // Red
        input[0][y][x][1] = pixel.g / 255.0; // Green
        input[0][y][x][2] = pixel.b / 255.0; // Blue
      }
    }

    return input;
  }

  // Run inference using TFLite API - accepts File (mobile)
  static List<Map<String, dynamic>>? predict(dynamic imageInput) {
    if (!_isLoaded || _interpreter == null) {
      return null;
    }

    try {
      File imageFile;
      if (imageInput is File) {
        imageFile = imageInput;
      } else if (imageInput is Uint8List) {
        // Convert Uint8List to File temporarily (for mobile)
        throw UnsupportedError('Uint8List not directly supported on mobile, use File instead');
      } else {
        return null;
      }

      // Get input and output tensors using TFLite API
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();
      
      if (inputTensors.isEmpty || outputTensors.isEmpty) {
        print('Error: Model has no input or output tensors');
        return null;
      }

      final inputTensor = inputTensors[0];
      final outputTensor = outputTensors[0];
      
      // Get input shape from tensor (format: [batch, height, width, channels])
      final inputShape = inputTensor.shape;
      final inputSize = inputShape[1]; // Assuming square input [1, size, size, 3]
      
      print('Input tensor shape: $inputShape');
      print('Output tensor shape: ${outputTensor.shape}');

      // Preprocess image to match model input requirements
      final input = preprocessImage(imageFile, inputSize);

      // Prepare output buffer based on output tensor shape
      // Output shape is typically [1, num_classes] for classification
      final outputShape = outputTensor.shape;
      final numClasses = outputShape.length > 1 ? outputShape[1] : outputShape[0];
      
      // tflite_flutter's run() method requires EXACT shape match
      // For [1, 2] shape, we need nested: [[0.0, 0.0]]
      // For [2] shape, we need flat: [0.0, 0.0]
      dynamic output;
      if (outputShape.length == 2) {
        // Shape is [batch, num_classes] - create nested list to match exactly
        final batchSize = outputShape[0];
        output = List.generate(batchSize, (_) => List.generate(numClasses, (_) => 0.0));
      } else {
        // Shape is [num_classes] - create flat list
        output = List.generate(numClasses, (_) => 0.0);
      }

      // Run inference using TFLite Interpreter API
      _interpreter!.run(input, output);

      // Process predictions from output buffer
      // Extract predictions based on output structure
      List<double> rawLogits;
      if (output is List && output.isNotEmpty && output[0] is List) {
        // Nested output: [[logit0, logit1]] for [1, 2] shape
        rawLogits = (output[0] as List<dynamic>).map<double>((e) => e.toDouble()).toList();
      } else {
        // Flat output: [logit0, logit1] for [2] shape
        rawLogits = (output as List<dynamic>).map<double>((e) => e.toDouble()).toList();
      }
      
      // Apply softmax to convert logits to probabilities
      // Softmax formula: exp(x_i) / sum(exp(x_j)) for all j
      // Subtract max for numerical stability to prevent overflow
      print('Raw logits: $rawLogits');
      final maxLogit = rawLogits.reduce((a, b) => a > b ? a : b);
      final expLogits = rawLogits.map((logit) {
        final shifted = logit - maxLogit;
        // Clamp to prevent overflow/underflow
        final clamped = shifted > 20 ? 20.0 : (shifted < -20 ? -20.0 : shifted);
        return math.exp(clamped);
      }).toList();
      final sumExp = expLogits.reduce((a, b) => a + b);
      final probabilities = expLogits.map((exp) => exp / sumExp).toList();
      print('Probabilities after softmax: $probabilities');
      
      final results = <Map<String, dynamic>>[];

      for (int i = 0; i < probabilities.length; i++) {
        // Ensure confidence is between 0 and 1
        final confidence = probabilities[i].clamp(0.0, 1.0);
        results.add({
          'label': i < _labels.length ? _labels[i] : 'Class $i',
          'confidence': confidence,
          'index': i,
        });
      }

      // Sort by confidence (highest first)
      results.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));

      print('Top prediction: ${results[0]['label']} (${(results[0]['confidence'] * 100).toStringAsFixed(2)}%)');
      
      return results;
    } catch (e) {
      print('Error during TFLite prediction: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Get top prediction - accepts File (mobile) or Uint8List (for compatibility)
  static Map<String, dynamic>? getTopPrediction(dynamic imageInput) {
    final predictions = predict(imageInput);
    if (predictions == null || predictions.isEmpty) {
      return null;
    }
    return predictions[0];
  }

  // Dispose
  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels.clear();
    _isLoaded = false;
  }

  static bool get isLoaded => _isLoaded;
}

