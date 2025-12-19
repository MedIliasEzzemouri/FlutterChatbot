import 'dart:math' as math;
import '../models/llm_config.dart';
import '../models/chat_message.dart';
import 'llm_service.dart';
import 'rag_service.dart';
import 'web_search_service.dart';
import 'mcp_client.dart';

/// Types d'outils disponibles pour les agents AI
enum AgentTool {
  analyzeConcentration,  // Analyse du taux de concentration
  predictSuccess,        // Prédiction de réussite
  calculateAverage,      // Calcul de moyenne
  academicAdvice,        // Conseil académique
}

/// Données d'entrée pour l'analyse de concentration
class ConcentrationData {
  final int totalStudents;
  final int presentStudents;
  final int activeParticipants;
  final double averageQuizScore;
  final int attentionDuration; // en minutes

  ConcentrationData({
    required this.totalStudents,
    required this.presentStudents,
    required this.activeParticipants,
    required this.averageQuizScore,
    required this.attentionDuration,
  });

  Map<String, dynamic> toJson() => {
    'totalStudents': totalStudents,
    'presentStudents': presentStudents,
    'activeParticipants': activeParticipants,
    'averageQuizScore': averageQuizScore,
    'attentionDuration': attentionDuration,
  };
}

/// Données d'entrée pour la prédiction de réussite
class SuccessPredictionData {
  final int absences;
  final int totalSessions;
  final List<double> grades; // Notes obtenues
  final double currentAverage;

  SuccessPredictionData({
    required this.absences,
    required this.totalSessions,
    required this.grades,
    required this.currentAverage,
  });

  Map<String, dynamic> toJson() => {
    'absences': absences,
    'totalSessions': totalSessions,
    'grades': grades,
    'currentAverage': currentAverage,
  };
}

/// Agent AI avec outils spécialisés
class AIAgent {
  final LLMConfig config;
  final bool useRAG;
  final bool useWebSearch;
  final bool useMCP; // Utiliser le serveur MCP au lieu de l'API directe

  AIAgent({
    required this.config,
    this.useRAG = true,
    this.useWebSearch = true,
    this.useMCP = false, // Par défaut, utiliser l'API directe
  });

  /// Analyse le taux de concentration en classe
  Future<String> analyzeConcentration(ConcentrationData data) async {
    // Utiliser MCP si disponible
    if (useMCP) {
      try {
        final isHealthy = await MCPClient.checkHealth();
        if (isHealthy) {
          final result = await MCPClient.analyzeConcentration(
            totalStudents: data.totalStudents,
            presentStudents: data.presentStudents,
            activeParticipants: data.activeParticipants,
            averageQuizScore: data.averageQuizScore,
            attentionDuration: data.attentionDuration,
          );
          
          return _formatConcentrationResult(result);
        }
      } catch (e) {
        print('MCP error, using local calculation: $e');
      }
    }
    
    // Calcul local (fallback)
    // Calcul du taux de présence
    final attendanceRate = (data.presentStudents / data.totalStudents) * 100;
    
    // Calcul du taux de participation active
    final participationRate = (data.activeParticipants / data.presentStudents) * 100;
    
    // Score de concentration global (0-100)
    final concentrationScore = (
      (attendanceRate * 0.3) +
      (participationRate * 0.3) +
      (data.averageQuizScore * 0.3) +
      ((data.attentionDuration / 90) * 100 * 0.1) // 90 min = cours complet
    ).clamp(0.0, 100.0).toDouble();

    // Interprétation
    String interpretation;
    if (concentrationScore >= 80) {
      interpretation = 'Excellent taux de concentration. La classe est très engagée.';
    } else if (concentrationScore >= 60) {
      interpretation = 'Bon taux de concentration. Quelques améliorations possibles.';
    } else if (concentrationScore >= 40) {
      interpretation = 'Taux de concentration modéré. Des actions correctives sont recommandées.';
    } else {
      interpretation = 'Taux de concentration faible. Intervention nécessaire.';
    }

    // Construire le rapport
    final report = '''
📊 **Analyse du Taux de Concentration**

**Métriques calculées :**
- Taux de présence : ${attendanceRate.toStringAsFixed(1)}%
- Taux de participation active : ${participationRate.toStringAsFixed(1)}%
- Score moyen aux quiz : ${data.averageQuizScore.toStringAsFixed(1)}/20
- Durée d'attention moyenne : ${data.attentionDuration} minutes

**Score de concentration global : ${concentrationScore.toStringAsFixed(1)}/100**

**Interprétation :**
$interpretation

**Recommandations :**
${_getConcentrationRecommendations(concentrationScore, attendanceRate, participationRate)}
''';

    return report;
  }

  String _formatConcentrationResult(Map<String, dynamic> result) {
    final score = result['concentration_score'] as double;
    final attendance = result['attendance_rate'] as double;
    final participation = result['participation_rate'] as double;
    final interpretation = result['interpretation'] as String;
    final metrics = result['metrics'] as Map<String, dynamic>;
    
    return '''
📊 **Analyse du Taux de Concentration**

**Métriques calculées :**
- Taux de présence : ${attendance.toStringAsFixed(1)}%
- Taux de participation active : ${participation.toStringAsFixed(1)}%
- Score moyen aux quiz : ${metrics['average_quiz_score'].toStringAsFixed(1)}/20
- Durée d'attention moyenne : ${metrics['attention_duration']} minutes

**Score de concentration global : ${score.toStringAsFixed(1)}/100**

**Interprétation :**
$interpretation

**Recommandations :**
${_getConcentrationRecommendations(score, attendance, participation)}
''';
  }

  String _getConcentrationRecommendations(double score, double attendance, double participation) {
    final recommendations = <String>[];
    
    if (attendance < 80) {
      recommendations.add('• Améliorer le taux de présence (actuellement ${attendance.toStringAsFixed(1)}%)');
    }
    
    if (participation < 60) {
      recommendations.add('• Encourager la participation active en classe');
    }
    
    if (score < 60) {
      recommendations.add('• Varier les méthodes pédagogiques pour maintenir l\'attention');
      recommendations.add('• Introduire des activités interactives');
    }
    
    if (recommendations.isEmpty) {
      return '• Maintenir les bonnes pratiques actuelles';
    }
    
    return recommendations.join('\n');
  }

  /// Prédit la réussite académique basée sur absences et notes
  Future<String> predictSuccess(SuccessPredictionData data) async {
    // Utiliser MCP si disponible
    if (useMCP) {
      try {
        final isHealthy = await MCPClient.checkHealth();
        if (isHealthy) {
          final result = await MCPClient.predictSuccess(
            absences: data.absences,
            totalSessions: data.totalSessions,
            grades: data.grades,
            currentAverage: data.currentAverage,
          );
          
          return _formatSuccessResult(result);
        }
      } catch (e) {
        print('MCP error, using local calculation: $e');
      }
    }
    
    // Calcul local (fallback)
    // Calcul du taux d'absence
    final absenceRate = (data.absences / data.totalSessions) * 100;
    
    // Calcul de la tendance des notes
    double trend = 0;
    if (data.grades.length >= 2) {
      final recent = (data.grades.take(3).reduce((a, b) => a + b) / 
                    math.min(3, data.grades.length)).toDouble();
      final older = data.grades.length > 3 
          ? data.grades.skip(3).reduce((a, b) => a + b) / (data.grades.length - 3)
          : recent;
      trend = recent - older;
    }
    
    // Score de prédiction (0-100)
    double successScore = 50; // Base
    
    // Facteur absence (pénalité si > 20%)
    if (absenceRate > 30) {
      successScore -= 30; // Pénalité forte
    } else if (absenceRate > 20) {
      successScore -= 15;
    } else if (absenceRate < 10) {
      successScore += 10; // Bonus pour bonne assiduité
    }
    
    // Facteur moyenne actuelle
    if (data.currentAverage >= 16) {
      successScore += 25;
    } else if (data.currentAverage >= 14) {
      successScore += 15;
    } else if (data.currentAverage >= 12) {
      successScore += 5;
    } else if (data.currentAverage < 10) {
      successScore -= 20;
    }
    
    // Facteur tendance
    if (trend > 2) {
      successScore += 10; // Amélioration
    } else if (trend < -2) {
      successScore -= 10; // Dégradation
    }
    
    successScore = successScore.clamp(0, 100);
    
    // Probabilité de réussite
    String probability;
    String recommendation;
    
    if (successScore >= 80) {
      probability = 'Très élevée (${successScore.toStringAsFixed(0)}%)';
      recommendation = 'L\'étudiant a de très bonnes chances de réussite. Continuer sur cette lancée.';
    } else if (successScore >= 60) {
      probability = 'Élevée (${successScore.toStringAsFixed(0)}%)';
      recommendation = 'Bonnes chances de réussite. Maintenir les efforts et améliorer les points faibles.';
    } else if (successScore >= 40) {
      probability = 'Modérée (${successScore.toStringAsFixed(0)}%)';
      recommendation = 'Chances de réussite modérées. Actions correctives nécessaires : réduire les absences, améliorer les notes.';
    } else {
      probability = 'Faible (${successScore.toStringAsFixed(0)}%)';
      recommendation = 'Risque d\'échec élevé. Intervention urgente requise : suivi personnalisé, rattrapage, réduction drastique des absences.';
    }
    
    final report = '''
🎓 **Prédiction de Réussite Académique**

**Données analysées :**
- Nombre d'absences : ${data.absences}/${data.totalSessions} (${absenceRate.toStringAsFixed(1)}%)
- Moyenne actuelle : ${data.currentAverage.toStringAsFixed(2)}/20
- Nombre de notes : ${data.grades.length}
- Tendance : ${trend > 0 ? '+' : ''}${trend.toStringAsFixed(2)} points

**Probabilité de réussite : $probability**

**Analyse détaillée :**
${_getSuccessAnalysis(absenceRate, data.currentAverage, trend)}

**Recommandations :**
$recommendation

${_getSuccessRecommendations(absenceRate, data.currentAverage, trend)}
''';

    return report;
  }

  String _formatSuccessResult(Map<String, dynamic> result) {
    final successScore = result['success_score'] as double;
    final probability = result['probability'] as String;
    final absenceRate = result['absence_rate'] as double;
    final currentAverage = result['current_average'] as double;
    final trend = result['trend'] as double;
    final analysis = result['analysis'] as Map<String, dynamic>;
    
    return '''
🎓 **Prédiction de Réussite Académique**

**Données analysées :**
- Nombre d'absences : ${analysis['absences']}/${analysis['total_sessions']} (${absenceRate.toStringAsFixed(1)}%)
- Moyenne actuelle : ${currentAverage.toStringAsFixed(2)}/20
- Nombre de notes : ${(analysis['grades'] as List).length}
- Tendance : ${trend > 0 ? '+' : ''}${trend.toStringAsFixed(2)} points

**Probabilité de réussite : $probability (${successScore.toStringAsFixed(0)}%)**

**Analyse détaillée :**
${_getSuccessAnalysis(absenceRate, currentAverage, trend)}

**Recommandations :**
${_getSuccessRecommendations(absenceRate, currentAverage, trend)}
''';
  }

  String _getSuccessAnalysis(double absenceRate, double average, double trend) {
    final analysis = <String>[];
    
    if (absenceRate > 30) {
      analysis.add('⚠️ Taux d\'absence critique (>30%). Impact négatif majeur sur la réussite.');
    } else if (absenceRate > 20) {
      analysis.add('⚠️ Taux d\'absence élevé (>20%). Risque pour la validation du module.');
    } else {
      analysis.add('✅ Taux d\'absence acceptable.');
    }
    
    if (average >= 14) {
      analysis.add('✅ Excellente moyenne. Indicateur positif fort.');
    } else if (average >= 12) {
      analysis.add('✅ Bonne moyenne. Sur la bonne voie.');
    } else if (average >= 10) {
      analysis.add('⚠️ Moyenne juste au-dessus du seuil. Nécessite des efforts supplémentaires.');
    } else {
      analysis.add('❌ Moyenne insuffisante. Risque d\'échec élevé.');
    }
    
    if (trend > 1) {
      analysis.add('📈 Tendance positive. Amélioration des performances.');
    } else if (trend < -1) {
      analysis.add('📉 Tendance négative. Dégradation des performances.');
    } else {
      analysis.add('➡️ Performance stable.');
    }
    
    return analysis.join('\n');
  }

  String _getSuccessRecommendations(double absenceRate, double average, double trend) {
    final recommendations = <String>[];
    
    if (absenceRate > 20) {
      recommendations.add('• Réduire immédiatement les absences (objectif : <20%)');
      recommendations.add('• Planifier un rattrapage des cours manqués');
    }
    
    if (average < 12) {
      recommendations.add('• Améliorer la moyenne (objectif : ≥12/20)');
      recommendations.add('• Demander de l\'aide aux enseignants');
      recommendations.add('• Revoir les cours régulièrement');
    }
    
    if (trend < -1) {
      recommendations.add('• Identifier les causes de la baisse de performance');
      recommendations.add('• Mettre en place un plan de récupération');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('• Maintenir les bonnes pratiques actuelles');
      recommendations.add('• Continuer à assister régulièrement aux cours');
    }
    
    return recommendations.join('\n');
  }

  /// Génère une réponse en utilisant le LLM avec RAG et outils
  Future<String> generateResponseWithTools({
    required List<ChatMessage> messages,
    required String userQuery,
  }) async {
    // Détecter si l'utilisateur demande une analyse spécifique
    final lowerQuery = userQuery.toLowerCase();
    
    // Mots-clés pour les questions d'information (doivent utiliser RAG, pas les outils)
    final informationKeywords = [
      'quelle est', 'qu\'est-ce que', 'qu\'est ce que', 'comment est',
      'politique', 'règle', 'règlement', 'système', 'procédure',
      'explique', 'définir', 'définition', 'signifie', 'signification'
    ];
    
    // Vérifier si c'est une question d'information (doit utiliser RAG)
    final isInformationQuestion = informationKeywords.any((keyword) => lowerQuery.contains(keyword));
    
    // Vérifier si c'est une demande d'ANALYSE de concentration (avec données ou demande d'action)
    final isConcentrationAnalysisRequest = 
        (lowerQuery.contains('analyser') || lowerQuery.contains('analyse')) &&
        (lowerQuery.contains('concentration') || lowerQuery.contains('attention') || lowerQuery.contains('taux de présence')) &&
        !isInformationQuestion;
    
    // Vérifier si c'est une demande d'ANALYSE de réussite (avec données ou demande d'action)
    final isSuccessPredictionRequest = 
        (lowerQuery.contains('prédire') || lowerQuery.contains('prédiction') || lowerQuery.contains('chance de réussite')) &&
        (lowerQuery.contains('réussite') || lowerQuery.contains('absence') || lowerQuery.contains('note')) &&
        !isInformationQuestion;
    
    // Si c'est une question d'information, utiliser RAG directement (ne pas utiliser les outils)
    if (isInformationQuestion) {
      // Laisser passer pour utiliser RAG ci-dessous
    }
    // Sinon, si c'est une demande d'analyse de concentration
    else if (isConcentrationAnalysisRequest) {
      return '''Pour analyser le taux de concentration, j'ai besoin des données suivantes :
- Nombre total d'étudiants
- Nombre d'étudiants présents
- Nombre de participants actifs
- Score moyen aux quiz
- Durée moyenne d'attention

Ou utilisez le formulaire d'analyse dans l'interface pour une analyse automatique.''';
    }
    // Sinon, si c'est une demande de prédiction de réussite
    else if (isSuccessPredictionRequest) {
      return '''Pour prédire la réussite académique, j'ai besoin de :
- Nombre d'absences et nombre total de sessions
- Liste des notes obtenues
- Moyenne actuelle

Ou utilisez le formulaire de prédiction dans l'interface pour une analyse automatique.''';
    }
    
    // Décider quelle source utiliser : RAG, Web Search, ou les deux
    String enhancedQuery = userQuery;
    final List<String> contextParts = [];
    
    // 1. Utiliser RAG pour les informations EMSI
    if (useRAG) {
      final ragContext = RAGService.buildRAGContext(userQuery);
      if (ragContext.isNotEmpty) {
        contextParts.add(ragContext);
      }
    }
    
    // 2. Utiliser Web Search si nécessaire (Agentic AI)
    if (useWebSearch && WebSearchService.shouldUseWebSearch(userQuery)) {
      // Afficher un indicateur de recherche (sera géré par l'UI)
      try {
        final searchResults = await WebSearchService.searchWeb(
          userQuery,
          maxResults: 5,
        );
        
        if (searchResults.isNotEmpty) {
          final webContext = WebSearchService.buildSearchContext(searchResults, userQuery);
          contextParts.add(webContext);
        }
      } catch (e) {
        print('Web search error: $e');
        // Continuer sans les résultats de recherche
      }
    }
    
    // 3. Construire le prompt final avec tous les contextes
    if (contextParts.isNotEmpty) {
      final allContext = contextParts.join('\n\n');
      enhancedQuery = '''$allContext

Question de l'utilisateur: $userQuery

Instructions pour la réponse:
${contextParts.length > 1 ? '- Vous avez accès à la fois à la base de connaissances EMSI et à des résultats de recherche web. Utilisez les deux sources de manière appropriée.\n' : ''}
- Si la réponse est dans la base de connaissances EMSI, priorisez cette source
- Si vous utilisez des informations de recherche web, citez les sources
- Si la réponse n'est PAS disponible dans les sources fournies, dites clairement "Je ne sais pas" ou "Cette information n'est pas disponible"
- NE JAMAIS inventer, deviner ou créer des informations
- Pour les questions générales (non spécifiques à EMSI), vous pouvez utiliser les résultats de recherche web''';
    } else {
      // Pas de contexte trouvé
      if (useRAG) {
        enhancedQuery = '''Question de l'utilisateur: $userQuery

Note: Aucune information pertinente trouvée dans la base de connaissances EMSI pour cette question.
${useWebSearch && WebSearchService.shouldUseWebSearch(userQuery) ? 'Une recherche web pourrait être utile pour cette question.' : ''}
Si la question concerne EMSI spécifiquement, dites que vous n'avez pas cette information.
Pour les questions générales, vous pouvez répondre normalement.''';
      }
    }
    
    // Créer un message temporaire avec le contexte enrichi
    final enhancedMessages = [
      ...messages,
      ChatMessage(
        id: 'temp',
        content: enhancedQuery,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    ];
    
    // Générer la réponse avec MistralAI (via MCP ou API directe)
    if (useMCP) {
      // Utiliser le serveur MCP
      try {
        final isHealthy = await MCPClient.checkHealth();
        if (isHealthy) {
          return await MCPClient.chat(
            messages: enhancedMessages,
            config: config,
          );
        } else {
          // Fallback vers API directe si MCP n'est pas disponible
          print('MCP server not available, falling back to direct API');
        }
      } catch (e) {
        print('MCP error, falling back to direct API: $e');
      }
    }
    
    // Utiliser l'API MistralAI directe
    return await LLMService.generateResponse(
      messages: enhancedMessages,
      config: config,
    );
  }
}

