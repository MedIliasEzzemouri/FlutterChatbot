import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/llm_config.dart';
import '../models/chat_message.dart';

/// Service pour interagir avec MistralAI
class LLMService {
  // Configuration MistralAI
  static const String _mistralApiKey = 'Vbubt3UZN2cQwc539tccs7X8KeImkhfC';
  static const String _mistralBaseUrl = 'https://api.mistral.ai/v1';

  /// Génère une réponse en utilisant MistralAI API
  static Future<String> generateResponse({
    required List<ChatMessage> messages,
    required LLMConfig config,
    String? apiKey,
  }) async {
    final key = apiKey ?? _mistralApiKey;
    
    if (key.isEmpty || key == 'YOUR_MISTRAL_API_KEY_HERE') {
      // Mode démo - retourne une réponse simulée
      return _generateDemoResponse(messages.last.content);
    }

    try {
      // Préparer les messages pour l'API Mistral
      final List<Map<String, dynamic>> apiMessages = [];
      
      // Ajouter le message système
      apiMessages.add({
        'role': 'system',
        'content': config.systemRole,
      });
      
      // Ajouter l'historique de conversation
      for (var message in messages) {
        apiMessages.add({
          'role': message.isUser ? 'user' : 'assistant',
          'content': message.content,
        });
      }

      // Préparer la requête
      final requestBody = {
        'model': config.fineTunedModelId ?? config.model,
        'messages': apiMessages,
        'temperature': config.temperature,
        'max_tokens': config.maxTokens,
        'top_p': config.topP,
      };

      final response = await http.post(
        Uri.parse('$_mistralBaseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['choices'][0]['message']['content'] as String;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error calling MistralAI API: $e');
      return 'Désolé, je rencontre un problème technique avec MistralAI. Veuillez réessayer plus tard.';
    }
  }

  /// Réponse de démonstration (quand aucune clé API n'est configurée)
  static String _generateDemoResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    
    if (lowerMessage.contains('concentration') || lowerMessage.contains('attention')) {
      return '''Analyse du taux de concentration :
      
Basé sur les données disponibles, je peux analyser le taux de concentration en classe. 
Pour une analyse précise, j'aurais besoin de :
- Données de présence
- Notes d'évaluation
- Observations comportementales

Souhaitez-vous que j'utilise l'outil d'analyse de concentration pour traiter vos données ?''';
    }
    
    if (lowerMessage.contains('réussite') || lowerMessage.contains('prédiction') || lowerMessage.contains('absence')) {
      return '''Prédiction de réussite académique :
      
Je peux analyser les chances de réussite d'un étudiant en fonction de :
- Nombre d'absences
- Notes obtenues
- Tendance des performances

Pour utiliser cet outil, veuillez fournir les données nécessaires (absences, notes, etc.).''';
    }
    
    // Vérifier si c'est une question sur EMSI spécifique
    if (lowerMessage.contains('emsi') || 
        lowerMessage.contains('note minimale') ||
        lowerMessage.contains('absence') ||
        lowerMessage.contains('moyenne') ||
        lowerMessage.contains('crédit') ||
        lowerMessage.contains('programme')) {
      return '''Je cherche dans ma base de connaissances EMSI...

Note : Pour obtenir des réponses précises basées sur la base de connaissances EMSI, veuillez configurer une clé API MistralAI dans les paramètres.

En attendant, vous pouvez utiliser les outils d'analyse (concentration, prédiction de réussite) qui fonctionnent sans clé API.''';
    }
    
    return '''Bonjour ! Je suis l'assistant EMSI ChatBot. 

Je peux vous aider avec :
- Analyse du taux de concentration en classe
- Prédiction de réussite selon absences/notes
- Questions académiques générales
- Explications de cours

Note : Pour utiliser les fonctionnalités complètes avec réponses basées sur la base de connaissances EMSI, veuillez configurer une clé API MistralAI dans les paramètres.

Comment puis-je vous aider aujourd'hui ?''';
  }

  /// Vérifie si une clé API est configurée
  static bool isApiKeyConfigured() {
    return _mistralApiKey.isNotEmpty && _mistralApiKey != 'YOUR_MISTRAL_API_KEY_HERE';
  }
  
  /// Liste des modèles MistralAI disponibles
  static const List<String> mistralModels = [
    'mistral-tiny',           // Fastest, smallest
    'mistral-small',          // Balanced (recommandé)
    'mistral-medium',         // Best quality (may require Pro)
    'mistral-large-latest',   // Latest large model
    'open-mistral-7b',        // Open source 7B
    'open-mixtral-8x7b',      // Open source Mixtral
  ];
}
