import 'dart:convert';
import 'package:http/http.dart' as http;

/// Résultat d'une recherche web
class WebSearchResult {
  final String title;
  final String url;
  final String snippet;
  final double? relevanceScore;

  WebSearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    this.relevanceScore,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'snippet': snippet,
    'relevanceScore': relevanceScore,
  };
}

/// Service de recherche web pour Agentic AI
class WebSearchService {
  // Option 1: DuckDuckGo Instant Answer API (gratuit, pas besoin d'API key)
  static const String _duckDuckGoUrl = 'https://api.duckduckgo.com/?q=';
  
  // Option 2: Google Custom Search (nécessite API key)
  static const String _googleSearchApiKey = 'YOUR_GOOGLE_SEARCH_API_KEY_HERE';
  static const String _googleSearchEngineId = 'YOUR_SEARCH_ENGINE_ID_HERE';
  static const String _googleSearchUrl = 'https://www.googleapis.com/customsearch/v1';
  
  // Option 3: SerpAPI (alternative, nécessite API key)
  static const String _serpApiKey = 'YOUR_SERP_API_KEY_HERE';
  static const String _serpApiUrl = 'https://serpapi.com/search.json';

  /// Effectue une recherche web
  /// Retourne une liste de résultats pertinents
  static Future<List<WebSearchResult>> searchWeb(
    String query, {
    int maxResults = 5,
    bool useGoogle = false,
    bool useSerp = false,
  }) async {
    try {
      // Essayer d'abord DuckDuckGo (gratuit)
      if (!useGoogle && !useSerp) {
        final results = await _searchDuckDuckGo(query, maxResults);
        if (results.isNotEmpty) return results;
      }

      // Si Google Search est configuré
      if (useGoogle && _googleSearchApiKey != 'YOUR_GOOGLE_SEARCH_API_KEY_HERE') {
        return await _searchGoogle(query, maxResults);
      }

      // Si SerpAPI est configuré
      if (useSerp && _serpApiKey != 'YOUR_SERP_API_KEY_HERE') {
        return await _searchSerpAPI(query, maxResults);
      }

      // Fallback: recherche DuckDuckGo HTML scraping (basique)
      return await _searchDuckDuckGoHTML(query, maxResults);
    } catch (e) {
      print('Error in web search: $e');
      return [];
    }
  }

  /// Recherche avec DuckDuckGo Instant Answer API
  static Future<List<WebSearchResult>> _searchDuckDuckGo(
    String query,
    int maxResults,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_duckDuckGoUrl${Uri.encodeComponent(query)}&format=json&no_html=1'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = <WebSearchResult>[];

        // DuckDuckGo retourne des "RelatedTopics" et "Results"
        if (data['AbstractText'] != null && data['AbstractText'].toString().isNotEmpty) {
          results.add(WebSearchResult(
            title: data['Heading'] ?? query,
            url: data['AbstractURL'] ?? '',
            snippet: data['AbstractText'],
            relevanceScore: 1.0,
          ));
        }

        // Ajouter les RelatedTopics
        if (data['RelatedTopics'] != null) {
          final topics = data['RelatedTopics'] as List;
          for (var topic in topics.take(maxResults - results.length)) {
            if (topic is Map && topic['Text'] != null) {
              results.add(WebSearchResult(
                title: topic['Text'].toString().split('.')[0],
                url: topic['FirstURL'] ?? '',
                snippet: topic['Text'] ?? '',
                relevanceScore: 0.8,
              ));
            }
          }
        }

        return results;
      }
    } catch (e) {
      print('DuckDuckGo search error: $e');
    }
    return [];
  }

  /// Recherche avec Google Custom Search API
  static Future<List<WebSearchResult>> _searchGoogle(
    String query,
    int maxResults,
  ) async {
    try {
      final url = Uri.parse(_googleSearchUrl).replace(queryParameters: {
        'key': _googleSearchApiKey,
        'cx': _googleSearchEngineId,
        'q': query,
        'num': maxResults.toString(),
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = <WebSearchResult>[];

        if (data['items'] != null) {
          for (var item in data['items']) {
            results.add(WebSearchResult(
              title: item['title'] ?? '',
              url: item['link'] ?? '',
              snippet: item['snippet'] ?? '',
              relevanceScore: 1.0,
            ));
          }
        }

        return results;
      }
    } catch (e) {
      print('Google search error: $e');
    }
    return [];
  }

  /// Recherche avec SerpAPI
  static Future<List<WebSearchResult>> _searchSerpAPI(
    String query,
    int maxResults,
  ) async {
    try {
      final url = Uri.parse(_serpApiUrl).replace(queryParameters: {
        'api_key': _serpApiKey,
        'q': query,
        'engine': 'google',
        'num': maxResults.toString(),
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = <WebSearchResult>[];

        if (data['organic_results'] != null) {
          for (var item in data['organic_results']) {
            results.add(WebSearchResult(
              title: item['title'] ?? '',
              url: item['link'] ?? '',
              snippet: item['snippet'] ?? '',
              relevanceScore: 1.0,
            ));
          }
        }

        return results;
      }
    } catch (e) {
      print('SerpAPI search error: $e');
    }
    return [];
  }

  /// Recherche DuckDuckGo via HTML scraping (fallback basique)
  static Future<List<WebSearchResult>> _searchDuckDuckGoHTML(
    String query,
    int maxResults,
  ) async {
    try {
      // Utiliser l'API HTML de DuckDuckGo
      final response = await http.get(
        Uri.parse('https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(query)}'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        // Parsing HTML basique (peut être amélioré avec un parser HTML)
        final html = response.body;
        final results = <WebSearchResult>[];

        // Extraire les résultats (pattern basique)
        final regex = RegExp(
          r'<a class="result__a".*?href="([^"]+)".*?>(.*?)</a>.*?<a class="result__snippet".*?>(.*?)</a>',
          multiLine: true,
          dotAll: true,
        );

        final matches = regex.allMatches(html);
        for (var match in matches.take(maxResults)) {
          results.add(WebSearchResult(
            title: _cleanHtml(match.group(2) ?? ''),
            url: match.group(1) ?? '',
            snippet: _cleanHtml(match.group(3) ?? ''),
            relevanceScore: 0.7,
          ));
        }

        return results;
      }
    } catch (e) {
      print('DuckDuckGo HTML search error: $e');
    }
    return [];
  }

  /// Nettoie le HTML d'un texte
  static String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Construit un contexte enrichi à partir des résultats de recherche
  static String buildSearchContext(List<WebSearchResult> results, String originalQuery) {
    if (results.isEmpty) {
      return '';
    }

    final contextBuilder = StringBuffer();
    contextBuilder.writeln('=== RÉSULTATS DE RECHERCHE WEB ===');
    contextBuilder.writeln('Question recherchée: $originalQuery\n');
    contextBuilder.writeln('Informations trouvées sur le web:');

    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      contextBuilder.writeln('\n${i + 1}. ${result.title}');
      contextBuilder.writeln('   URL: ${result.url}');
      contextBuilder.writeln('   Résumé: ${result.snippet}');
    }

    contextBuilder.writeln('\n=== FIN DES RÉSULTATS ===');
    contextBuilder.writeln('\nInstructions:');
    contextBuilder.writeln('- Utilisez ces informations pour répondre à la question');
    contextBuilder.writeln('- Citez les sources quand c\'est pertinent');
    contextBuilder.writeln('- Si les informations sont contradictoires, mentionnez-le');
    contextBuilder.writeln('- Restez factuel et précis');

    return contextBuilder.toString();
  }

  /// Détecte si une question nécessite une recherche web
  static bool shouldUseWebSearch(String query) {
    final lowerQuery = query.toLowerCase();
    
    // Mots-clés qui indiquent un besoin de recherche web
    final webSearchKeywords = [
      'actualité', 'actualités', 'news', 'nouveau', 'nouvelle', 'récent', 'récemment',
      'aujourd\'hui', 'maintenant', 'actuel', 'actuelle', 'dernier', 'dernière',
      'date', 'quand', 'où', 'qui est', 'qui a', 'combien coûte', 'prix',
      'comparer', 'différence entre', 'vs', 'versus', 'meilleur', 'meilleure',
      'tendance', 'statistique', 'statistiques', 'données', 'étude', 'recherche',
      'événement', 'événements', 'manifestation', 'conférence',
    ];

    // Questions sur des sujets nécessitant des infos à jour
    final timeSensitivePatterns = [
      'en 2024', 'en 2025', 'cette année', 'cette semaine',
      'dernières nouvelles', 'derniers développements',
    ];

    // Vérifier les mots-clés
    final hasWebSearchKeyword = webSearchKeywords.any((keyword) => lowerQuery.contains(keyword));
    final hasTimeSensitivePattern = timeSensitivePatterns.any((pattern) => lowerQuery.contains(pattern));

    // Vérifier si c'est une question factuelle qui pourrait nécessiter une recherche
    final isFactualQuestion = lowerQuery.startsWith('qui ') ||
        lowerQuery.startsWith('quand ') ||
        lowerQuery.startsWith('où ') ||
        lowerQuery.startsWith('combien ') ||
        lowerQuery.contains('quel est le') ||
        lowerQuery.contains('quelle est la');

    // Ne pas utiliser la recherche web pour les questions EMSI internes
    final isEMSIInternal = lowerQuery.contains('emsi') &&
        (lowerQuery.contains('politique') ||
         lowerQuery.contains('règle') ||
         lowerQuery.contains('note minimale') ||
         lowerQuery.contains('absence'));

    // Utiliser la recherche web si:
    // 1. Contient des mots-clés de recherche web ET n'est pas une question EMSI interne
    // 2. Contient des patterns temporels
    // 3. Est une question factuelle générale (pas EMSI)
    return !isEMSIInternal && (hasWebSearchKeyword || hasTimeSensitivePattern || (isFactualQuestion && !lowerQuery.contains('emsi')));
  }
}

