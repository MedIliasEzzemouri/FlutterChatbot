/// Service RAG (Retrieval-Augmented Generation)
/// Permet de récupérer des informations pertinentes depuis une base de connaissances
/// avant de générer une réponse
class RAGService {
  // Base de connaissances simulée (dans un vrai projet, utiliser une base vectorielle)
  static final List<Map<String, String>> _knowledgeBase = [
    {
      'title': 'Système de notation EMSI',
      'content': 'EMSI utilise un système de notation sur 20 points. La note minimale pour valider un module est 10/20.',
      'category': 'academic',
    },
    {
      'title': 'Politique d\'absences',
      'content': 'Les étudiants ne peuvent pas dépasser 30% d\'absences par module. Au-delà, le module est non validé.',
      'category': 'academic',
    },
    {
      'title': 'Calcul de la moyenne',
      'content': 'La moyenne générale est calculée en pondérant chaque module par ses crédits ECTS.',
      'category': 'academic',
    },
    {
      'title': 'Concentration en classe',
      'content': 'Le taux de concentration peut être mesuré par : présence active, participation, résultats aux quiz, temps d\'attention.',
      'category': 'pedagogy',
    },
    {
      'title': 'Facteurs de réussite',
      'content': 'Les principaux facteurs de réussite incluent : assiduité (>80%), moyenne des notes (>12/20), participation active en classe.',
      'category': 'pedagogy',
    },
    {
      'title': 'Programmes disponibles',
      'content': 'EMSI propose des programmes en : Génie Informatique, Génie Logiciel, Intelligence Artificielle, Réseaux et Télécommunications.',
      'category': 'general',
    },
  ];

  /// Recherche dans la base de connaissances
  static List<Map<String, String>> searchKnowledgeBase(String query, {int maxResults = 3}) {
    final lowerQuery = query.toLowerCase();
    final results = <Map<String, String>>[];
    
    // Mots-clés importants à rechercher
    final importantKeywords = ['politique', 'absences', 'absence', 'règle', 'règlement', 
                               'note', 'notation', 'moyenne', 'calcul', 'crédit', 'ects',
                               'concentration', 'réussite', 'facteur', 'programme'];
    
    for (var doc in _knowledgeBase) {
      final title = doc['title']!.toLowerCase();
      final content = doc['content']!.toLowerCase();
      
      // Score de pertinence amélioré
      int score = 0;
      final queryWords = lowerQuery.split(' ').where((w) => w.length > 2).toList();
      
      // Recherche exacte dans le titre (score élevé)
      if (title.contains(lowerQuery) || lowerQuery.contains(title)) {
        score += 10;
      }
      
      // Recherche de mots-clés importants
      for (var keyword in importantKeywords) {
        if (lowerQuery.contains(keyword)) {
          if (title.contains(keyword)) score += 5;
          if (content.contains(keyword)) score += 2;
        }
      }
      
      // Recherche de mots individuels
      for (var word in queryWords) {
        if (word.length > 3) { // Ignorer les mots trop courts
          if (title.contains(word)) score += 3;
          if (content.contains(word)) score += 1;
        }
      }
      
      // Bonus si plusieurs mots correspondent
      final matchingWords = queryWords.where((w) => 
        title.contains(w) || content.contains(w)
      ).length;
      if (matchingWords > 1) {
        score += matchingWords;
      }
      
      if (score > 0) {
        results.add({
          ...doc,
          'relevance_score': score.toString(),
        });
      }
    }
    
    // Trier par score de pertinence
    results.sort((a, b) {
      final scoreA = int.parse(a['relevance_score'] ?? '0');
      final scoreB = int.parse(b['relevance_score'] ?? '0');
      return scoreB.compareTo(scoreA);
    });
    
    return results.take(maxResults).toList();
  }

  /// Construit un contexte enrichi pour le LLM
  static String buildRAGContext(String query) {
    final relevantDocs = searchKnowledgeBase(query);
    
    if (relevantDocs.isEmpty) {
      return '';
    }
    
    final contextBuilder = StringBuffer();
    contextBuilder.writeln('=== BASE DE CONNAISSANCES EMSI ===');
    contextBuilder.writeln('IMPORTANT: Utilisez UNIQUEMENT les informations ci-dessous pour répondre.');
    contextBuilder.writeln('Si la réponse n\'est pas dans ces informations, dites "Je ne sais pas" ou "Cette information n\'est pas disponible dans ma base de connaissances".');
    contextBuilder.writeln('NE JAMAIS inventer ou deviner des informations sur EMSI.\n');
    contextBuilder.writeln('Informations pertinentes :\n');
    
    for (var doc in relevantDocs) {
      contextBuilder.writeln('📚 ${doc['title']}');
      contextBuilder.writeln('${doc['content']}\n');
    }
    
    contextBuilder.writeln('=== FIN DE LA BASE DE CONNAISSANCES ===');
    contextBuilder.writeln('\nRappel: Répondez UNIQUEMENT en vous basant sur les informations ci-dessus. Si la question nécessite des informations non disponibles, dites-le clairement.');
    
    return contextBuilder.toString();
  }

  /// Ajoute un document à la base de connaissances (pour extension future)
  static void addDocument(String title, String content, String category) {
    _knowledgeBase.add({
      'title': title,
      'content': content,
      'category': category,
    });
  }

  /// Recherche avec embeddings (pour extension future avec vraie base vectorielle)
  static Future<List<Map<String, String>>> searchWithEmbeddings(String query) async {
    // TODO: Implémenter avec une vraie base vectorielle (Pinecone, Weaviate, etc.)
    // Pour l'instant, utiliser la recherche textuelle simple
    return searchKnowledgeBase(query);
  }
}

