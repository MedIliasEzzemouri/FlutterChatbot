import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/llm_config.dart';

/// Client MCP (Model Context Protocol) pour communiquer avec le serveur MCP
class MCPClient {
  // URL du serveur MCP
  // Pour Android emulator: http://10.0.2.2:8000
  // Pour iOS simulator: http://localhost:8000
  // Pour web: http://localhost:8000
  // Pour device physique: http://VOTRE_IP_LOCALE:8000
  static const String baseUrl = 'http://10.0.2.2:8000';
  
  /// Vérifie si le serveur MCP est disponible
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('MCP Server health check failed: $e');
      return false;
    }
  }

  /// Envoie une requête de chat au serveur MCP
  static Future<String> chat({
    required List<ChatMessage> messages,
    required LLMConfig config,
  }) async {
    try {
      // Préparer les messages pour l'API MCP
      final List<Map<String, dynamic>> apiMessages = messages.map((msg) {
        return {
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.content,
          'timestamp': msg.timestamp.toIso8601String(),
        };
      }).toList();

      final requestBody = {
        'messages': apiMessages,
        'model': config.model,
        'temperature': config.temperature,
        'max_tokens': config.maxTokens,
        'top_p': config.topP,
        'system_role': config.systemRole,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/mcp/chat'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['response'] as String;
      } else {
        throw Exception('MCP Server Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error calling MCP chat: $e');
      rethrow;
    }
  }

  /// Recherche RAG dans la base de connaissances
  static Future<List<Map<String, String>>> ragSearch(String query, {int maxResults = 3}) async {
    try {
      final requestBody = {
        'query': query,
        'max_results': maxResults,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/mcp/rag'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final results = jsonResponse['results'] as List;
        return results.map((r) => {
          'title': r['title'] as String,
          'content': r['content'] as String,
          'category': r['category'] as String,
        }).toList();
      } else {
        throw Exception('MCP RAG Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error calling MCP RAG: $e');
      return [];
    }
  }

  /// Exécute un outil d'analyse
  static Future<Map<String, dynamic>> executeTool({
    required String toolName,
    required Map<String, dynamic> parameters,
  }) async {
    try {
      final requestBody = {
        'tool_name': toolName,
        'parameters': parameters,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/mcp/tools'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['result'] as Map<String, dynamic>;
      } else {
        throw Exception('MCP Tool Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error calling MCP tool: $e');
      rethrow;
    }
  }

  /// Analyse de concentration via MCP
  static Future<Map<String, dynamic>> analyzeConcentration({
    required int totalStudents,
    required int presentStudents,
    required int activeParticipants,
    required double averageQuizScore,
    required int attentionDuration,
  }) async {
    return await executeTool(
      toolName: 'analyze_concentration',
      parameters: {
        'total_students': totalStudents,
        'present_students': presentStudents,
        'active_participants': activeParticipants,
        'average_quiz_score': averageQuizScore,
        'attention_duration': attentionDuration,
      },
    );
  }

  /// Prédiction de réussite via MCP
  static Future<Map<String, dynamic>> predictSuccess({
    required int absences,
    required int totalSessions,
    required List<double> grades,
    required double currentAverage,
  }) async {
    return await executeTool(
      toolName: 'predict_success',
      parameters: {
        'absences': absences,
        'total_sessions': totalSessions,
        'grades': grades,
        'current_average': currentAverage,
      },
    );
  }

  /// Liste tous les outils disponibles
  static Future<List<Map<String, dynamic>>> listTools() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mcp/tools/list'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return List<Map<String, dynamic>>.from(jsonResponse['tools']);
      } else {
        throw Exception('MCP Tools List Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error listing MCP tools: $e');
      return [];
    }
  }

  /// Prédiction Deep Learning (images)
  static Future<Map<String, dynamic>> deepLearningPredict({
    required List<int> imageBytes,
    required String modelType, // 'pneumonia' ou 'fruits'
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/dl/predict?model_type=$modelType'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'image.jpg',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('DL Predict Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error calling DL predict: $e');
      rethrow;
    }
  }
}

