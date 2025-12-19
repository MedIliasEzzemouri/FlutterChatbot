import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class PneumoniaClassifierPage extends StatefulWidget {
  const PneumoniaClassifierPage({super.key});

  @override
  State<PneumoniaClassifierPage> createState() => _PneumoniaClassifierPageState();
}

class _PneumoniaClassifierPageState extends State<PneumoniaClassifierPage> {
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
        _errorMessage = 'API server is not available. Please start the FastAPI server.\n\nSee API_SETUP.md for instructions.';
      }
    });
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium, // Medium preset to reduce buffer warnings on emulator
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
    
    final prediction = await ApiService.predictPneumonia(imageFile);
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
    
    final prediction = await ApiService.predictPneumoniaFromBytes(imageBytes, 'image.jpg');
    setState(() {
      _prediction = prediction;
      _isLoading = false;
      if (prediction == null) {
        _errorMessage = 'Failed to classify image. Check if API server is running.';
      }
    });
  }

  Color _getResultColor() {
    if (_prediction == null) return Colors.grey;
    final label = _prediction!['label'] as String;
    return label.toUpperCase() == 'PNEUMONIA' ? Colors.red : Colors.green;
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
        title: const Text('Pneumonia Classifier'),
        backgroundColor: Colors.red,
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
                    // Medical Disclaimer
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: Colors.orange.shade100,
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This is for educational purposes only. Not a medical diagnosis.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Camera Preview or Captured Image
                    Expanded(
                      flex: 3,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _capturedImage != null
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
                    
                    if (_prediction != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getResultColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getResultColor()),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _prediction!['label'].toString().toUpperCase() ==
                                      'PNEUMONIA'
                                  ? Icons.warning
                                  : Icons.check_circle,
                              size: 48,
                              color: _getResultColor(),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _prediction!['label'].toString().toUpperCase() == 'PNEUMONIA'
                                  ? 'PNEUMONIA DETECTED'
                                  : 'NORMAL',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _getResultColor(),
                              ),
                            ),
                            const SizedBox(height: 12),
                                Text(
                                  'Score: ${((_prediction!['confidence_percentage'] ?? (_prediction!['confidence'] as double) * 100) as double).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: _getResultColor(),
                                  ),
                                ),
                            const SizedBox(height: 8),
                            Text(
                              _prediction!['label'].toString().toUpperCase() == 'PNEUMONIA'
                                  ? '⚠️ Please consult a medical professional'
                                  : '✅ Chest X-ray appears normal',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
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
                          // Camera disabled on emulator - use Gallery instead
                          // if (!kIsWeb && _cameraController != null &&
                          //     _cameraController!.value.isInitialized)
                          //   FloatingActionButton(
                          //     onPressed: _captureImage,
                          //     backgroundColor: Colors.red,
                          //     child: const Icon(Icons.camera_alt),
                          //   ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

