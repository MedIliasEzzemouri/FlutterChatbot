# Serveur MCP (Model Context Protocol) - EMSI ChatBot

## 📋 Vue d'ensemble

Serveur MCP qui expose des endpoints REST pour :
- **Chat avec LLM** (MistralAI)
- **RAG** (Recherche dans la base de connaissances)
- **Outils d'analyse** (Concentration, Prédiction de réussite)
- **Deep Learning** (Prédictions d'images)

## 🚀 Installation

### Prérequis

- Python 3.9+
- pip

### Installation des dépendances

```bash
cd mcp_server
pip install -r requirements.txt
```

## 🏃 Lancement du serveur

```bash
python main.py
```

Le serveur sera accessible sur : `http://localhost:8000`

## 📡 Endpoints disponibles

### 1. Health Check

```http
GET /health
```

### 2. Chat avec LLM

```http
POST /mcp/chat
Content-Type: application/json

{
  "messages": [
    {"role": "user", "content": "Bonjour"}
  ],
  "model": "mistral-small",
  "temperature": 0.7,
  "max_tokens": 1000
}
```

### 3. Recherche RAG

```http
POST /mcp/rag
Content-Type: application/json

{
  "query": "politique d'absences",
  "max_results": 3
}
```

### 4. Exécution d'outils

```http
POST /mcp/tools
Content-Type: application/json

{
  "tool_name": "analyze_concentration",
  "parameters": {
    "total_students": 30,
    "present_students": 25,
    "active_participants": 20,
    "average_quiz_score": 14.0,
    "attention_duration": 75
  }
}
```

### 5. Prédiction Deep Learning

```http
POST /dl/predict?model_type=pneumonia
Content-Type: multipart/form-data

file: [image bytes]
```

## 🔧 Configuration

### Pour Android Emulator

Dans Flutter, utilisez : `http://10.0.2.2:8000`

### Pour iOS Simulator

Utilisez : `http://localhost:8000`

### Pour Web

Utilisez : `http://localhost:8000`

### Pour Device Physique

Utilisez l'IP locale de votre machine : `http://192.168.x.x:8000`

## 📚 Documentation API

Une fois le serveur lancé, accédez à :
- **Swagger UI** : `http://localhost:8000/docs`
- **ReDoc** : `http://localhost:8000/redoc`

## 🔐 Sécurité

En production :
1. Configurez CORS avec des origines spécifiques
2. Ajoutez l'authentification (JWT, API keys)
3. Utilisez HTTPS
4. Limitez les rate limits

## 🐳 Docker (optionnel)

```dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

**Dernière mise à jour** : Décembre 2024

