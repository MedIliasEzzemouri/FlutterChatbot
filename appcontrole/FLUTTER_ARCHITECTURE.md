# Architecture Flutter - Guide Complet

## 📱 Architecture de Flutter

### Vue d'ensemble

Flutter est un framework de développement multiplateforme qui utilise le langage Dart. Il permet de créer des applications natives pour iOS, Android, Web, Windows, macOS et Linux à partir d'une seule base de code.

### Architecture en Couches

```
┌─────────────────────────────────────────┐
│   Application Layer (UI)                │
│   - Widgets                              │
│   - Material/Cupertino Design            │
│   - State Management                     │
├─────────────────────────────────────────┤
│   Framework Layer (Dart)                 │
│   - Rendering Engine                     │
│   - Animation System                     │
│   - Gesture Detection                    │
│   - Widget Tree                          │
├─────────────────────────────────────────┤
│   Engine Layer (C++)                     │
│   - Skia (2D Graphics)                   │
│   - Dart VM                              │
│   - Platform Channels                    │
├─────────────────────────────────────────┤
│   Embedder Layer                         │
│   - Platform-specific code               │
│   - Android/iOS/Web/Windows/macOS/Linux  │
└─────────────────────────────────────────┘
```

### Principes Fondamentaux

#### 1. **Tout est un Widget**
Dans Flutter, **TOUT** est un widget :
- Les boutons, textes, images → Widgets
- Les layouts (Row, Column, Stack) → Widgets
- Les pages, écrans → Widgets
- Même l'application elle-même → Widget

#### 2. **Composition plutôt qu'Héritage**
Les widgets sont composés ensemble pour créer des interfaces complexes :

```dart
Scaffold(                    // Widget de structure
  appBar: AppBar(...),      // Widget d'en-tête
  body: Column(             // Widget de layout
    children: [
      Text(...),            // Widget de texte
      ElevatedButton(...),  // Widget de bouton
    ],
  ),
)
```

#### 3. **Rendu Déclaratif**
L'interface utilisateur est décrite de manière déclarative. Flutter reconstruit automatiquement les parties qui changent.

#### 4. **Hot Reload**
Permet de voir les changements instantanément sans redémarrer l'application.

---

## 🧩 Structure des Widgets

### Types de Widgets

#### 1. **StatelessWidget** (Widget Statique)

**Caractéristiques :**
- Immutable (immuable après création)
- Plus performant
- Pas d'état interne
- Utilisé pour les éléments UI statiques

**Exemple :**

```dart
class MyText extends StatelessWidget {
  final String text;
  
  const MyText({super.key, required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Text(text);
  }
}
```

**Quand l'utiliser :**
- Affichage de texte statique
- Images
- Icônes
- Widgets qui ne changent jamais

#### 2. **StatefulWidget** (Widget avec État)

**Caractéristiques :**
- Peut changer d'état pendant son cycle de vie
- Utilise `setState()` pour déclencher une reconstruction
- Plus complexe mais nécessaire pour l'interactivité

**Exemple :**

```dart
class Counter extends StatefulWidget {
  const Counter({super.key});
  
  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0;  // État mutable
  
  void _increment() {
    setState(() {  // Déclenche une reconstruction
      _count++;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _increment,
      child: Text('Count: $_count'),
    );
  }
}
```

**Quand l'utiliser :**
- Formulaires avec saisie utilisateur
- Compteurs, toggles
- Listes dynamiques
- Toute UI qui change en réponse à des interactions

### Arborescence des Widgets (Widget Tree)

```
MyApp (StatelessWidget)
└── MaterialApp
    ├── Theme
    └── HomePage (StatefulWidget)
        └── Scaffold
            ├── AppBar
            │   ├── Text (titre)
            │   └── IconButton
            └── Body
                └── Column
                    ├── Text
                    ├── TextField
                    └── ElevatedButton
                        └── Text
```

### Widgets Courants

#### **MaterialApp**
Point d'entrée de l'application Material Design.

```dart
MaterialApp(
  title: 'Mon App',
  theme: ThemeData(...),
  home: HomePage(),
  routes: {...},
)
```

#### **Scaffold**
Structure de base d'une page Material Design.

```dart
Scaffold(
  appBar: AppBar(title: Text('Titre')),
  body: Center(child: Text('Contenu')),
  drawer: Drawer(...),
  floatingActionButton: FloatingActionButton(...),
)
```

#### **Layout Widgets**

**Row** : Alignement horizontal
```dart
Row(
  children: [
    Icon(Icons.star),
    Text('5.0'),
  ],
)
```

**Column** : Alignement vertical
```dart
Column(
  children: [
    Text('Ligne 1'),
    Text('Ligne 2'),
  ],
)
```

**Stack** : Superposition de widgets
```dart
Stack(
  children: [
    Image(...),
    Positioned(
      bottom: 0,
      child: Text('Overlay'),
    ),
  ],
)
```

#### **Input Widgets**

**TextField** : Saisie de texte
```dart
TextField(
  controller: _controller,
  decoration: InputDecoration(labelText: 'Email'),
)
```

**ElevatedButton** : Bouton élevé
```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Cliquer'),
)
```

---

## 🔄 Cycle de Vie des Widgets

### Cycle de Vie d'un StatefulWidget

```
1. createState()
   ↓
2. initState()              ← Initialisation (UNE SEULE FOIS)
   ↓
3. didChangeDependencies() ← Appelé après initState()
   ↓
4. build()                  ← Construction de l'UI (PLUSIEURS FOIS)
   ↓
   [setState()]             ← Déclenche une nouvelle construction
   ↓
5. didUpdateWidget()        ← Quand le widget parent change
   ↓
6. deactivate()             ← Avant retrait de l'arbre
   ↓
7. dispose()                ← Nettoyage final (UNE SEULE FOIS)
```

### Détails des Méthodes

#### **1. createState()**
```dart
@override
State<MyWidget> createState() => _MyWidgetState();
```
- Crée l'objet State
- Appelé automatiquement par Flutter
- Ne pas appeler manuellement

#### **2. initState()**
```dart
@override
void initState() {
  super.initState();
  // Initialisation ici
  _controller = TextEditingController();
  _loadData();
}
```
- **Appelé UNE SEULE FOIS** lors de la création
- **Ne peut pas utiliser BuildContext** pour la navigation
- Parfait pour :
  - Initialiser les contrôleurs
  - Charger des données initiales
  - Configurer des écouteurs
  - Appels API initiaux

#### **3. didChangeDependencies()**
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // Appelé après initState()
  // Appelé quand les dépendances changent (ex: InheritedWidget)
}
```
- Appelé après `initState()`
- Appelé quand les dépendances changent
- Peut utiliser `BuildContext` ici

#### **4. build()**
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(...);
}
```
- **Appelé PLUSIEURS FOIS** :
  - Après `initState()`
  - Après `setState()`
  - Quand le widget parent change
- **Ne doit pas modifier l'état** directement
- Doit retourner un Widget
- Doit être **pur** (même entrée → même sortie)

#### **5. setState()**
```dart
setState(() {
  _count++;  // Modifier l'état
});
```
- Déclenche une reconstruction du widget
- Ne pas appeler dans `build()`
- Ne pas appeler de manière synchrone dans des callbacks asynchrones sans vérifier `mounted`

#### **6. didUpdateWidget()**
```dart
@override
void didUpdateWidget(MyWidget oldWidget) {
  super.didUpdateWidget(oldWidget);
  // Comparer oldWidget avec widget
  if (oldWidget.value != widget.value) {
    // Mettre à jour si nécessaire
  }
}
```
- Appelé quand le widget parent change
- Permet de comparer l'ancien et le nouveau widget
- Utile pour optimiser les mises à jour

#### **7. deactivate()**
```dart
@override
void deactivate() {
  // Widget retiré de l'arbre (mais peut être réinséré)
  super.deactivate();
}
```
- Appelé avant que le widget soit retiré de l'arbre
- Le widget peut être réinséré ailleurs
- Ne pas faire de nettoyage définitif ici

#### **8. dispose()**
```dart
@override
void dispose() {
  // Nettoyage final
  _controller.dispose();
  _subscription.cancel();
  super.dispose();
}
```
- **Appelé UNE SEULE FOIS** quand le widget est définitivement détruit
- **CRUCIAL** : Toujours disposer les ressources :
  - Contrôleurs (TextEditingController, etc.)
  - Streams, Subscriptions
  - Timers
  - Écouteurs
- Évite les **fuites mémoire**

### Exemple Complet dans le Projet

```dart
class _LoginPageState extends State<LoginPage> {
  // Contrôleurs (à disposer)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Initialisation
    print('LoginPage initialisée');
  }
  
  @override
  void dispose() {
    // CRUCIAL : Nettoyer les contrôleurs
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  void _login() {
    setState(() {
      _isLoading = true;  // Déclenche build()
    });
    
    // ... logique de connexion
    
    setState(() {
      _isLoading = false;  // Déclenche build() à nouveau
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Construit l'UI
    return Scaffold(...);
  }
}
```

### Points Importants

#### ✅ Bonnes Pratiques

1. **Toujours appeler super.initState() et super.dispose()**
2. **Toujours disposer les contrôleurs dans dispose()**
3. **Vérifier `mounted` avant setState() dans les callbacks asynchrones**
4. **Ne pas modifier l'état dans build()**
5. **Utiliser const pour les widgets statiques**

#### ❌ Erreurs Communes

1. **Oublier dispose()** → Fuites mémoire
2. **setState() dans build()** → Boucle infinie
3. **Modifier l'état dans build()** → Comportement imprévisible
4. **Utiliser BuildContext après dispose()** → Erreur

### Exemple avec Vérification `mounted`

```dart
Future<void> _loadData() async {
  final data = await fetchData();
  
  // Vérifier que le widget est toujours monté
  if (!mounted) return;
  
  setState(() {
    _data = data;
  });
}
```

---

## 🏗️ Architecture dans ce Projet

### Structure des Fichiers

```
lib/
├── main.dart              # Point d'entrée
├── models/                # Modèles de données
│   ├── chat_message.dart
│   └── llm_config.dart
├── services/             # Services (logique métier)
│   ├── llm_service.dart
│   ├── rag_service.dart
│   ├── ai_agent.dart
│   └── mcp_client.dart
└── [pages].dart          # Pages/Écrans (UI)
    ├── login_page.dart
    ├── home_page.dart
    └── chatbot_page.dart
```

### Exemple : LoginPage

```dart
class LoginPage extends StatefulWidget {  // Widget avec état
  const LoginPage({super.key});
  
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // État
  final _emailController = TextEditingController();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Initialisation
  }
  
  @override
  void dispose() {
    _emailController.dispose();  // Nettoyage
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(  // Widget de structure
      appBar: AppBar(...),  // Widget d'en-tête
      body: Form(  // Widget de formulaire
        child: Column(  // Widget de layout
          children: [
            TextField(...),  // Widget d'input
            ElevatedButton(...),  // Widget de bouton
          ],
        ),
      ),
    );
  }
}
```

---

## 📊 Résumé Visuel

### Flux de Vie d'un Widget

```
Création
  ↓
initState() → Initialisation
  ↓
build() → Affichage initial
  ↓
[Utilisateur interagit]
  ↓
setState() → Modification état
  ↓
build() → Reconstruction UI
  ↓
[Widget parent change]
  ↓
didUpdateWidget() → Mise à jour
  ↓
[Widget retiré]
  ↓
deactivate() → Retrait temporaire
  ↓
dispose() → Destruction finale
```

### Comparaison Stateless vs Stateful

| Aspect | StatelessWidget | StatefulWidget |
|--------|----------------|----------------|
| État | ❌ Aucun | ✅ Oui |
| Performance | ⚡ Plus rapide | 🐢 Légèrement plus lent |
| Complexité | 🟢 Simple | 🟡 Plus complexe |
| Utilisation | Affichage statique | UI interactive |
| Reconstruction | Rare | Fréquente (setState) |

---

## 🎯 Concepts Clés

### 1. **Widget Tree (Arbre de Widgets)**
Hiérarchie de widgets qui compose l'UI. Flutter traverse cet arbre pour rendre l'interface.

### 2. **Element Tree (Arbre d'Éléments)**
Représentation intermédiaire qui maintient les références aux widgets.

### 3. **Render Tree (Arbre de Rendu)**
Représentation optimisée pour le rendu graphique.

### 4. **BuildContext**
Contexte de construction qui fournit des informations sur la position dans l'arbre.

### 5. **Key**
Identifiant unique pour les widgets (utile pour les listes).

---

## 💡 Conseils Pratiques

1. **Utilisez const** quand possible pour améliorer les performances
2. **Évitez les reconstructions inutiles** avec des widgets const
3. **Disposez toujours** les ressources dans dispose()
4. **Vérifiez mounted** avant setState() dans les callbacks async
5. **Séparez la logique** : Services pour la logique, Widgets pour l'UI

---

**Dernière mise à jour** : Décembre 2024

