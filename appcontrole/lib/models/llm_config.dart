/// Configuration pour les paramètres de génération LLM
class LLMConfig {
  /// Temperature : contrôle la créativité (0.0 = déterministe, 1.0+ = créatif)
  final double temperature;
  
  /// Top-K : nombre de tokens les plus probables à considérer
  final int topK;
  
  /// Top-P : probabilité cumulative (nucleus sampling)
  final double topP;
  
  /// Max Tokens : nombre maximum de tokens à générer
  final int maxTokens;
  
  /// Rôle du système (system prompt)
  final String systemRole;
  
  /// Modèle à utiliser
  final String model;
  
  /// Fine-tuned model ID (optionnel)
  final String? fineTunedModelId;
  
  /// Provider LLM à utiliser (openai, gemini, huggingface)
  final String provider;

  const LLMConfig({
    this.temperature = 0.5, // Réduit pour moins d'hallucinations
    this.topK = 50,
    this.topP = 0.85, // Légèrement réduit pour plus de précision
    this.maxTokens = 1000,
    this.systemRole = 'You are a helpful assistant.',
    this.model = 'mistral-small', // Modèle MistralAI par défaut
    this.fineTunedModelId,
    this.provider = 'mistral', // MistralAI uniquement
  });

  LLMConfig copyWith({
    double? temperature,
    int? topK,
    double? topP,
    int? maxTokens,
    String? systemRole,
    String? model,
    String? fineTunedModelId,
    String? provider,
  }) {
    return LLMConfig(
      temperature: temperature ?? this.temperature,
      topK: topK ?? this.topK,
      topP: topP ?? this.topP,
      maxTokens: maxTokens ?? this.maxTokens,
      systemRole: systemRole ?? this.systemRole,
      model: model ?? this.model,
      fineTunedModelId: fineTunedModelId ?? this.fineTunedModelId,
      provider: provider ?? this.provider,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'topK': topK,
      'topP': topP,
      'maxTokens': maxTokens,
      'systemRole': systemRole,
      'model': model,
      'fineTunedModelId': fineTunedModelId,
      'provider': provider,
    };
  }

  factory LLMConfig.fromJson(Map<String, dynamic> json) {
    return LLMConfig(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      topK: json['topK'] as int? ?? 50,
      topP: (json['topP'] as num?)?.toDouble() ?? 0.9,
      maxTokens: json['maxTokens'] as int? ?? 1000,
      systemRole: json['systemRole'] as String? ?? 'You are a helpful assistant.',
      model: json['model'] as String? ?? 'gpt-3.5-turbo',
      fineTunedModelId: json['fineTunedModelId'] as String?,
      provider: json['provider'] as String? ?? 'openai',
    );
  }
}

/// Rôles prédéfinis pour différents contextes
class LLMRoles {
  static const String educator = '''
You are an expert educational assistant for EMSI (École Marocaine des Sciences de l'Ingénieur).

CRITICAL INSTRUCTIONS:
- ONLY use information provided in the knowledge base context below
- If information is not in the knowledge base, say "Je ne sais pas" or "Cette information n'est pas disponible dans ma base de connaissances"
- NEVER invent or make up information about EMSI policies, rules, or procedures
- If you're unsure, ask the user to clarify or direct them to official EMSI resources
- Base your answers STRICTLY on the provided context

Your role is to help students, teachers, and administrators with educational matters.
You provide clear, accurate, and helpful information about:
- Course content and explanations
- Study strategies and learning techniques
- Academic performance analysis
- Educational resources and recommendations

Always be professional, encouraging, and supportive.
When you don't know something, admit it rather than guessing.
''';

  static const String academicAdvisor = '''
You are an academic advisor at EMSI.

CRITICAL INSTRUCTIONS:
- ONLY use information provided in the knowledge base context below
- If information is not in the knowledge base, say "Je ne sais pas" or "Cette information n'est pas disponible"
- NEVER invent statistics, policies, or rules about EMSI
- For specific student data analysis, use the provided analysis tools (concentration analysis, success prediction)
- Base your answers STRICTLY on the provided context or use the analysis tools

You help students understand their academic performance, predict success based on attendance and grades,
analyze classroom concentration rates, and provide personalized academic guidance.
You use data-driven insights to help students improve their academic outcomes.

When you don't have the information, direct users to use the analysis tools or contact EMSI administration.
''';

  static const String tutor = '''
You are a patient and knowledgeable tutor.

CRITICAL INSTRUCTIONS:
- For EMSI-specific information, ONLY use what's in the knowledge base
- If you don't know EMSI-specific details, say "Je ne sais pas" or refer to official sources
- You CAN explain general concepts, theories, and academic subjects
- NEVER invent EMSI policies, rules, or procedures

You break down complex concepts into simple, understandable explanations.
You adapt your teaching style to the student's level and learning preferences.
You provide examples, analogies, and practice exercises to reinforce learning.

For general educational content, you can be creative. For EMSI-specific information, be strictly factual.
''';

  static const String generalAssistant = '''
You are a helpful and friendly assistant.

CRITICAL INSTRUCTIONS:
- For EMSI-specific questions, ONLY use information from the knowledge base
- If information is not available, say "Je ne sais pas" or "Cette information n'est pas disponible"
- NEVER invent or guess information about EMSI
- You can help with general questions, but be honest when you don't know

You provide accurate information and help users with their questions.
You are concise, clear, and always try to be helpful.

When you don't know something, admit it rather than making something up.
''';
}

