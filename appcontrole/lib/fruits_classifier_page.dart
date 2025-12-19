import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class FruitsClassifierPage extends StatefulWidget {
  const FruitsClassifierPage({super.key});

  @override
  State<FruitsClassifierPage> createState() => _FruitsClassifierPageState();
}

class _FruitsClassifierPageState extends State<FruitsClassifierPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isApiAvailable = false;
  bool _isLoading = false;
  File? _capturedImage;
  Uint8List? _capturedImageBytes; // For web
  Map<String, dynamic>? _prediction;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Skip camera on emulator - use Gallery instead
    // if (!kIsWeb) {
    //   _initializeCamera();
    // }
    _checkApiHealth();
  }

  Future<void> _checkApiHealth() async {
    setState(() => _isLoading = true);
    final isHealthy = await ApiService.checkHealth();
    setState(() {
      _isApiAvailable = isHealthy;
      _isLoading = false;
      if (!isHealthy) {
        _errorMessage = 'API server is not available. Please start the FastAPI server.\n\nMake sure the fruits endpoint is available at /fruits/predict';
      }
    });
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium, // Changed from high to medium to reduce buffer warnings on emulator
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Camera initialization failed: $e';
      });
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      final imageFile = File(image.path);
      setState(() {
        _capturedImage = imageFile;
        _prediction = null;
      });
      _classifyImage(imageFile);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture image: $e';
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (kIsWeb) {
          // Web: read as bytes
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _capturedImageBytes = bytes;
            _capturedImage = null;
            _prediction = null;
          });
          _classifyImageBytes(bytes);
        } else {
          // Mobile: use File
          final imageFile = File(pickedFile.path);
          setState(() {
            _capturedImage = imageFile;
            _capturedImageBytes = null;
            _prediction = null;
          });
          _classifyImage(imageFile);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _classifyImage(File imageFile) async {
    if (kIsWeb) return; // Should not be called on web
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final prediction = await ApiService.predictFruits(imageFile);
    setState(() {
      _prediction = prediction;
      _isLoading = false;
      if (prediction == null) {
        _errorMessage = 'Failed to classify image. Check if API server is running.';
      }
    });
  }

  Future<void> _classifyImageBytes(Uint8List imageBytes) async {
    if (!kIsWeb) return; // Should only be called on web
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final prediction = await ApiService.predictFruitsFromBytes(imageBytes, 'image.jpg');
    setState(() {
      _prediction = prediction;
      _isLoading = false;
      if (prediction == null) {
        _errorMessage = 'Failed to classify image. Check if API server is running.';
      }
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fruits Classifier'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading && !_isApiAvailable
          ? const Center(child: CircularProgressIndicator())
          : (_errorMessage != null && !_isApiAvailable)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _checkApiHealth,
                          child: const Text('Retry Connection'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Camera Preview or Captured Image
                    Expanded(
                      flex: 3,
                      child: _capturedImage != null
                          ? Image.file(
                              _capturedImage!,
                              fit: BoxFit.contain,
                            )
                          : _capturedImageBytes != null
                              ? Image.memory(
                                  _capturedImageBytes!,
                                  fit: BoxFit.contain,
                                )
                          : kIsWeb
                              ? const Center(
                                  child: Text('Select an image from gallery'),
                                )
                              : const Center(
                                  child: Text('Use Gallery button to select an image'),
                                ),
                    ),

                    // Prediction Results
                    if (_prediction != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Prediction: ${_prediction!['label']}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Confidence: ${((_prediction!['confidence_percentage'] ?? (_prediction!['confidence'] as double) * 100) as double).toStringAsFixed(2)}%',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Controls
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: (_capturedImage != null || _capturedImageBytes != null)
                                ? () {
                                    setState(() {
                                      _capturedImage = null;
                                      _capturedImageBytes = null;
                                      _prediction = null;
                                    });
                                  }
                                : _pickImageFromGallery,
                            icon: Icon(
                              (_capturedImage != null || _capturedImageBytes != null)
                                  ? Icons.refresh
                                  : Icons.photo_library,
                            ),
                            label: Text(
                              (_capturedImage != null || _capturedImageBytes != null) ? 'Retake' : 'Gallery',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

