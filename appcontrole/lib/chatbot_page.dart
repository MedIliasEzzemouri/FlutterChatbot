import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/llm_config.dart';
import '../services/ai_agent.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  
  // Configuration LLM MistralAI (paramètres optimisés)
  LLMConfig _llmConfig = LLMConfig(
    systemRole: LLMRoles.educator,
    temperature: 0.5, // Réduit pour plus de précision
    topK: 50,
    topP: 0.85, // Légèrement réduit
    maxTokens: 1000,
    model: 'mistral-small', // Modèle MistralAI par défaut
    provider: 'mistral',
  );
  
  bool _useRAG = true;
  bool _useWebSearch = true;
  bool _useMCP = false; // Utiliser le serveur MCP
  late AIAgent _agent;
  
  @override
  void initState() {
    super.initState();
    _agent = AIAgent(
      config: _llmConfig,
      useRAG: _useRAG,
      useWebSearch: _useWebSearch,
      useMCP: _useMCP,
    );
    _addWelcomeMessage();
  }

  // Formulaires pour les outils
  bool _showConcentrationForm = false;
  bool _showSuccessForm = false;
  
  // Contrôleurs pour le formulaire de concentration
  final TextEditingController _totalStudentsController = TextEditingController();
  final TextEditingController _presentStudentsController = TextEditingController();
  final TextEditingController _activeParticipantsController = TextEditingController();
  final TextEditingController _quizScoreController = TextEditingController();
  final TextEditingController _attentionDurationController = TextEditingController();
  
  // Contrôleurs pour le formulaire de prédiction
  final TextEditingController _absencesController = TextEditingController();
  final TextEditingController _totalSessionsController = TextEditingController();
  final TextEditingController _gradesController = TextEditingController();
  final TextEditingController _currentAverageController = TextEditingController();


  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      id: const Uuid().v4(),
      content: '''Bonjour ! Je suis l'assistant EMSI ChatBot 🤖

Je peux vous aider avec :
• 📊 Analyse du taux de concentration en classe
• 🎓 Prédiction de réussite selon absences/notes
• 💬 Questions académiques générales
• 📚 Explications de cours

Utilisez les boutons ci-dessous pour accéder aux outils d'analyse, ou posez-moi directement une question !''',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _totalStudentsController.dispose();
    _presentStudentsController.dispose();
    _activeParticipantsController.dispose();
    _quizScoreController.dispose();
    _attentionDurationController.dispose();
    _absencesController.dispose();
    _totalSessionsController.dispose();
    _gradesController.dispose();
    _currentAverageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Ajouter le message de l'utilisateur
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      // Générer la réponse avec l'agent AI
      final response = await _agent.generateResponseWithTools(
        messages: _messages,
        userQuery: text,
      );

      final botMessage = ChatMessage(
        id: const Uuid().v4(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(botMessage);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          id: const Uuid().v4(),
          content: 'Désolé, une erreur s\'est produite : $e',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _analyzeConcentration() async {
    final totalStudents = int.tryParse(_totalStudentsController.text) ?? 0;
    final presentStudents = int.tryParse(_presentStudentsController.text) ?? 0;
    final activeParticipants = int.tryParse(_activeParticipantsController.text) ?? 0;
    final quizScore = double.tryParse(_quizScoreController.text) ?? 0.0;
    final attentionDuration = int.tryParse(_attentionDurationController.text) ?? 0;

    if (totalStudents == 0 || presentStudents == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs requis')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _showConcentrationForm = false;
    });

    try {
      final data = ConcentrationData(
        totalStudents: totalStudents,
        presentStudents: presentStudents,
        activeParticipants: activeParticipants,
        averageQuizScore: quizScore,
        attentionDuration: attentionDuration,
      );

      final result = await _agent.analyzeConcentration(data);

      setState(() {
        _messages.add(ChatMessage(
          id: const Uuid().v4(),
          content: result,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });

      // Réinitialiser les champs
      _totalStudentsController.clear();
      _presentStudentsController.clear();
      _activeParticipantsController.clear();
      _quizScoreController.clear();
      _attentionDurationController.clear();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          id: const Uuid().v4(),
          content: 'Erreur lors de l\'analyse : $e',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _predictSuccess() async {
    final absences = int.tryParse(_absencesController.text) ?? 0;
    final totalSessions = int.tryParse(_totalSessionsController.text) ?? 0;
    final currentAverage = double.tryParse(_currentAverageController.text) ?? 0.0;
    
    // Parser les notes (séparées par des virgules)
    final gradesText = _gradesController.text;
    final grades = gradesText
        .split(',')
        .map((s) => double.tryParse(s.trim()) ?? 0.0)
        .where((g) => g > 0)
        .toList();

    if (totalSessions == 0 || grades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs requis')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _showSuccessForm = false;
    });

    try {
      final data = SuccessPredictionData(
        absences: absences,
        totalSessions: totalSessions,
        grades: grades,
        currentAverage: currentAverage > 0 ? currentAverage : (grades.reduce((a, b) => a + b) / grades.length),
      );

      final result = await _agent.predictSuccess(data);

      setState(() {
        _messages.add(ChatMessage(
          id: const Uuid().v4(),
          content: result,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });

      // Réinitialiser les champs
      _absencesController.clear();
      _totalSessionsController.clear();
      _gradesController.clear();
      _currentAverageController.clear();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          id: const Uuid().v4(),
          content: 'Erreur lors de la prédiction : $e',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => _SettingsDialog(
        config: _llmConfig,
        useRAG: _useRAG,
        useWebSearch: _useWebSearch,
        useMCP: _useMCP,
        onConfigChanged: (config, useRAG, useWebSearch, useMCP) {
          setState(() {
            _llmConfig = config;
            _useRAG = useRAG;
            _useWebSearch = useWebSearch;
            _useMCP = useMCP;
            _agent = AIAgent(
              config: config,
              useRAG: useRAG,
              useWebSearch: useWebSearch,
              useMCP: useMCP,
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EMSI ChatBot'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: Column(
        children: [
          // Outils rapides
          if (!_showConcentrationForm && !_showSuccessForm)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.teal.shade50,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showConcentrationForm = true;
                          _showSuccessForm = false;
                        });
                      },
                      icon: const Icon(Icons.analytics, size: 18),
                      label: const Text('Analyse Concentration'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showSuccessForm = true;
                          _showConcentrationForm = false;
                        });
                      },
                      icon: const Icon(Icons.trending_up, size: 18),
                      label: const Text('Prédiction Réussite'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Formulaire d'analyse de concentration
          if (_showConcentrationForm)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '📊 Analyse de Concentration',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() => _showConcentrationForm = false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _totalStudentsController,
                          decoration: const InputDecoration(
                            labelText: 'Total étudiants',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _presentStudentsController,
                          decoration: const InputDecoration(
                            labelText: 'Présents',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _activeParticipantsController,
                          decoration: const InputDecoration(
                            labelText: 'Participants actifs',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _quizScoreController,
                          decoration: const InputDecoration(
                            labelText: 'Score moyen quiz (/20)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _attentionDurationController,
                    decoration: const InputDecoration(
                      labelText: 'Durée attention moyenne (minutes)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _analyzeConcentration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Analyser'),
                    ),
                  ),
                ],
              ),
            ),

          // Formulaire de prédiction de réussite
          if (_showSuccessForm)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '🎓 Prédiction de Réussite',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() => _showSuccessForm = false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _absencesController,
                          decoration: const InputDecoration(
                            labelText: 'Absences',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _totalSessionsController,
                          decoration: const InputDecoration(
                            labelText: 'Total sessions',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _gradesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (séparées par des virgules, ex: 14, 15, 12)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _currentAverageController,
                    decoration: const InputDecoration(
                      labelText: 'Moyenne actuelle (/20)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _predictSuccess,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Prédire'),
                    ),
                  ),
                ],
              ),
            ),

          // Messages de chat
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final message = _messages[index];
                return _ChatBubble(message: message);
              },
            ),
          ),

          // Zone de saisie
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Tapez votre message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Colors.teal,
                  disabledColor: Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.teal : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _SettingsDialog extends StatefulWidget {
  final LLMConfig config;
  final bool useRAG;
  final bool useWebSearch;
  final bool useMCP;
  final Function(LLMConfig, bool, bool, bool) onConfigChanged;

  const _SettingsDialog({
    required this.config,
    required this.useRAG,
    required this.useWebSearch,
    required this.useMCP,
    required this.onConfigChanged,
  });

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late LLMConfig _config;
  late bool _useRAG;
  late bool _useWebSearch;
  late bool _useMCP;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _config = widget.config;
    _useRAG = widget.useRAG;
    _useWebSearch = widget.useWebSearch;
    _useMCP = widget.useMCP;
    _selectedRole = _config.systemRole;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Paramètres LLM'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Modèle MistralAI:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _config.model,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'mistral-tiny',
                  child: Text('Mistral Tiny (Plus rapide)'),
                ),
                DropdownMenuItem(
                  value: 'mistral-small',
                  child: Text('Mistral Small (Recommandé)'),
                ),
                DropdownMenuItem(
                  value: 'mistral-medium',
                  child: Text('Mistral Medium (Meilleure qualité)'),
                ),
                DropdownMenuItem(
                  value: 'mistral-large-latest',
                  child: Text('Mistral Large (Premium)'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(model: value!);
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Rôle du système:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedRole,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: LLMRoles.educator,
                  child: const Text('Éducateur EMSI'),
                ),
                DropdownMenuItem(
                  value: LLMRoles.academicAdvisor,
                  child: const Text('Conseiller Académique'),
                ),
                DropdownMenuItem(
                  value: LLMRoles.tutor,
                  child: const Text('Tuteur'),
                ),
                DropdownMenuItem(
                  value: LLMRoles.generalAssistant,
                  child: const Text('Assistant Général'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                  _config = _config.copyWith(systemRole: value);
                });
              },
            ),
            const SizedBox(height: 16),
            Text('Temperature: ${_config.temperature.toStringAsFixed(1)}'),
            Slider(
              value: _config.temperature,
              min: 0.0,
              max: 2.0,
              divisions: 20,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(temperature: value);
                });
              },
            ),
            const SizedBox(height: 8),
            Text('Top-K: ${_config.topK}'),
            Slider(
              value: _config.topK.toDouble(),
              min: 1,
              max: 100,
              divisions: 99,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(topK: value.toInt());
                });
              },
            ),
            const SizedBox(height: 8),
            Text('Top-P: ${_config.topP.toStringAsFixed(2)}'),
            Slider(
              value: _config.topP,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(topP: value);
                });
              },
            ),
            const SizedBox(height: 8),
            Text('Max Tokens: ${_config.maxTokens}'),
            Slider(
              value: _config.maxTokens.toDouble(),
              min: 100,
              max: 4000,
              divisions: 39,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(maxTokens: value.toInt());
                });
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Utiliser RAG'),
              value: _useRAG,
              onChanged: (value) {
                setState(() {
                  _useRAG = value ?? true;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Recherche Web (Agentic AI)'),
              subtitle: const Text('Recherche automatique sur le web pour les questions nécessitant des infos à jour'),
              value: _useWebSearch,
              onChanged: (value) {
                setState(() {
                  _useWebSearch = value ?? true;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Utiliser Serveur MCP'),
              subtitle: const Text('Utiliser le serveur MCP au lieu de l\'API directe (nécessite serveur local)'),
              value: _useMCP,
              onChanged: (value) {
                setState(() {
                  _useMCP = value ?? false;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfigChanged(_config, _useRAG, _useWebSearch, _useMCP);
            Navigator.pop(context);
          },
          child: const Text('Sauvegarder'),
        ),
      ],
    );
  }
}

