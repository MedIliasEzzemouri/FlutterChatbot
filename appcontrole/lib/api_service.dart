import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class ApiService {
  /// API Service for connecting to the lab_pneumonia FastAPI deployment backend
  /// 
  /// The backend deployment code is located in: ../lab_pneumonia/fastapi_deployment/
  /// To start the server, navigate to that folder and run: uvicorn main:app --reload
  /// 
  /// Base URL configuration:
  /// - Android emulator: http://10.0.2.2:8000 (default)
  /// - iOS simulator: http://localhost:8000
  /// - Physical device: http://YOUR_COMPUTER_IP:8000
  /// - Web: http://localhost:8000
  /// 
  /// API Endpoints (from lab_pneumonia/fastapi_deployment/main.py):
  /// - GET  /health - Health check
  /// - POST /predict - Pneumonia classification
  /// - POST /fruits/predict - Fruits classification
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator default
  
  /// Predict pneumonia from chest X-ray image
  static Future<Map<String, dynamic>?> predictPneumonia(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/predict'),
      );
      
      // Read image file as bytes
      final imageBytes = await imageFile.readAsBytes();
      final filename = imageFile.path.split('/').last;
      
      // Determine content type from file extension
      String contentType = 'image/jpeg';
      if (filename.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (filename.toLowerCase().endsWith('.jpg') || filename.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      }
      
      // Create multipart file with content type
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename,
        contentType: MediaType.parse(contentType),
      );
      request.files.add(multipartFile);
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return {
          'label': jsonData['prediction'],
          'confidence': jsonData['confidence'] as double,
          'confidence_percentage': jsonData['confidence_percentage'] as double,
        };
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error calling pneumonia API: $e');
      return null;
    }
  }
  
  /// Predict pneumonia from image bytes (for web compatibility)
  static Future<Map<String, dynamic>?> predictPneumoniaFromBytes(
    Uint8List imageBytes,
    String filename,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/predict'),
      );
      
      // Determine content type from filename
      String contentType = 'image/jpeg';
      if (filename.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (filename.toLowerCase().endsWith('.jpg') || filename.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      }
      
      // Add image bytes with proper content type
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename,
        contentType: MediaType.parse(contentType),
      );
      request.files.add(multipartFile);
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return {
          'label': jsonData['prediction'],
          'confidence': jsonData['confidence'] as double,
          'confidence_percentage': jsonData['confidence_percentage'] as double,
        };
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error calling pneumonia API: $e');
      return null;
    }
  }
  
  /// Predict fruits from image
  static Future<Map<String, dynamic>?> predictFruits(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/fruits/predict'),
      );
      
      // Read image file as bytes
      final imageBytes = await imageFile.readAsBytes();
      final filename = imageFile.path.split('/').last;
      
      // Determine content type from file extension
      String contentType = 'image/jpeg';
      if (filename.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (filename.toLowerCase().endsWith('.jpg') || filename.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      }
      
      // Create multipart file with content type
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename,
        contentType: MediaType.parse(contentType),
      );
      request.files.add(multipartFile);
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return {
          'label': jsonData['prediction'],
          'confidence': jsonData['confidence'] as double,
          'confidence_percentage': jsonData['confidence_percentage'] as double,
        };
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error calling fruits API: $e');
      return null;
    }
  }
  
  /// Predict fruits from image bytes (for web compatibility)
  static Future<Map<String, dynamic>?> predictFruitsFromBytes(
    Uint8List imageBytes,
    String filename,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/fruits/predict'),
      );
      
      // Determine content type from filename
      String contentType = 'image/jpeg';
      if (filename.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (filename.toLowerCase().endsWith('.jpg') || filename.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      }
      
      // Add image bytes with proper content type
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename,
        contentType: MediaType.parse(contentType),
      );
      request.files.add(multipartFile);
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return {
          'label': jsonData['prediction'],
          'confidence': jsonData['confidence'] as double,
          'confidence_percentage': jsonData['confidence_percentage'] as double,
        };
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error calling fruits API: $e');
      return null;
    }
  }
  
  /// Check if API server is running
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

