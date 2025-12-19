"""
Serveur MCP (Model Context Protocol) pour EMSI ChatBot
Supporte les clients Flutter (Web/Mobile) et Django
"""

from fastapi import FastAPI, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import uvicorn
from datetime import datetime
import json

app = FastAPI(
    title="EMSI MCP Server",
    description="Model Context Protocol Server for EMSI ChatBot",
    version="1.0.0"
)

# CORS pour permettre les requêtes depuis Flutter Web et Mobile
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En production, spécifiez les origines exactes
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==================== MODÈLES DE DONNÉES ====================

class Message(BaseModel):
    role: str  # "user" ou "assistant"
    content: str
    timestamp: Optional[str] = None

class ChatRequest(BaseModel):
    messages: List[Message]
    model: Optional[str] = "mistral-small"
    temperature: Optional[float] = 0.7
    max_tokens: Optional[int] = 1000
    top_p: Optional[float] = 0.9
    system_role: Optional[str] = None

class ChatResponse(BaseModel):
    response: str
    model: str
    usage: Optional[Dict[str, int]] = None
    timestamp: str

class ToolRequest(BaseModel):
    tool_name: str
    parameters: Dict[str, Any]

class ToolResponse(BaseModel):
    result: Any
    tool_name: str
    timestamp: str

class RAGRequest(BaseModel):
    query: str
    max_results: Optional[int] = 3

class RAGResponse(BaseModel):
    results: List[Dict[str, str]]
    query: str
    timestamp: str

# ==================== BASE DE CONNAISSANCES (RAG) ====================

KNOWLEDGE_BASE = [
    {
        "title": "Système de notation EMSI",
        "content": "EMSI utilise un système de notation sur 20 points. La note minimale pour valider un module est 10/20.",
        "category": "academic"
    },
    {
        "title": "Politique d'absences",
        "content": "Les étudiants ne peuvent pas dépasser 30% d'absences par module. Au-delà, le module est non validé.",
        "category": "academic"
    },
    {
        "title": "Calcul de la moyenne",
        "content": "La moyenne générale est calculée en pondérant chaque module par ses crédits ECTS.",
        "category": "academic"
    },
    {
        "title": "Concentration en classe",
        "content": "Le taux de concentration peut être mesuré par : présence active, participation, résultats aux quiz, temps d'attention.",
        "category": "pedagogy"
    },
    {
        "title": "Facteurs de réussite",
        "content": "Les principaux facteurs de réussite incluent : assiduité (>80%), moyenne des notes (>12/20), participation active en classe.",
        "category": "pedagogy"
    },
    {
        "title": "Programmes disponibles",
        "content": "EMSI propose des programmes en : Génie Informatique, Génie Logiciel, Intelligence Artificielle, Réseaux et Télécommunications.",
        "category": "general"
    }
]

def analyze_concentration(data: Dict[str, Any]) -> Dict[str, Any]:
    """Analyse le taux de concentration en classe"""
    total_students = data.get("total_students", 0)
    present_students = data.get("present_students", 0)
    active_participants = data.get("active_participants", 0)
    quiz_score = data.get("average_quiz_score", 0.0)
    attention_duration = data.get("attention_duration", 0)
    
    if total_students == 0:
        raise ValueError("total_students doit être supérieur à 0")
    
    attendance_rate = (present_students / total_students) * 100
    participation_rate = (active_participants / present_students) * 100 if present_students > 0 else 0
    
    concentration_score = (
        (attendance_rate * 0.3) +
        (participation_rate * 0.3) +
        (quiz_score * 0.3) +
        ((attention_duration / 90) * 100 * 0.1)
    )
    concentration_score = max(0, min(100, concentration_score))
    
    interpretation = ""
    if concentration_score >= 80:
        interpretation = "Excellent taux de concentration. La classe est très engagée."
    elif concentration_score >= 60:
        interpretation = "Bon taux de concentration. Quelques améliorations possibles."
    elif concentration_score >= 40:
        interpretation = "Taux de concentration modéré. Des actions correctives sont recommandées."
    else:
        interpretation = "Taux de concentration faible. Intervention nécessaire."
    
    return {
        "concentration_score": round(concentration_score, 2),
        "attendance_rate": round(attendance_rate, 2),
        "participation_rate": round(participation_rate, 2),
        "interpretation": interpretation,
        "metrics": {
            "total_students": total_students,
            "present_students": present_students,
            "active_participants": active_participants,
            "average_quiz_score": quiz_score,
            "attention_duration": attention_duration
        }
    }

def predict_success(data: Dict[str, Any]) -> Dict[str, Any]:
    """Prédit la réussite académique"""
    absences = data.get("absences", 0)
    total_sessions = data.get("total_sessions", 0)
    grades = data.get("grades", [])
    current_average = data.get("current_average", 0.0)
    
    if total_sessions == 0:
        raise ValueError("total_sessions doit être supérieur à 0")
    
    if not grades:
        if current_average > 0:
            grades = [current_average]
        else:
            raise ValueError("grades ou current_average requis")
    
    absence_rate = (absences / total_sessions) * 100
    
    # Calcul de la tendance
    trend = 0.0
    if len(grades) >= 2:
        recent = sum(grades[:3]) / min(3, len(grades))
        older = sum(grades[3:]) / (len(grades) - 3) if len(grades) > 3 else recent
        trend = recent - older
    
    # Score de prédiction
    success_score = 50.0
    
    if absence_rate > 30:
        success_score -= 30
    elif absence_rate > 20:
        success_score -= 15
    elif absence_rate < 10:
        success_score += 10
    
    if current_average >= 16:
        success_score += 25
    elif current_average >= 14:
        success_score += 15
    elif current_average >= 12:
        success_score += 5
    elif current_average < 10:
        success_score -= 20
    
    if trend > 2:
        success_score += 10
    elif trend < -2:
        success_score -= 10
    
    success_score = max(0, min(100, success_score))
    
    if success_score >= 80:
        probability = "Très élevée"
    elif success_score >= 60:
        probability = "Élevée"
    elif success_score >= 40:
        probability = "Modérée"
    else:
        probability = "Faible"
    
    return {
        "success_score": round(success_score, 2),
        "probability": probability,
        "absence_rate": round(absence_rate, 2),
        "current_average": current_average,
        "trend": round(trend, 2),
        "analysis": {
            "absences": absences,
            "total_sessions": total_sessions,
            "grades": grades,
            "trend_direction": "positive" if trend > 0 else "negative" if trend < 0 else "stable"
        }
    }

# ==================== ENDPOINTS MCP ====================

@app.get("/")
async def root():
    """Endpoint de santé"""
    return {
        "status": "online",
        "service": "EMSI MCP Server",
        "version": "1.0.0",
        "endpoints": {
            "chat": "/mcp/chat",
            "tools": "/mcp/tools",
            "rag": "/mcp/rag",
            "health": "/health"
        }
    }

@app.get("/health")
async def health():
    """Vérification de santé du serveur"""
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.post("/mcp/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    Endpoint principal pour les conversations avec le LLM
    Compatible avec le protocole MCP
    """
    try:
        # Ici, vous intégreriez votre appel à MistralAI
        # Pour l'instant, on simule une réponse
        # TODO: Intégrer l'API MistralAI réelle
        
        # Construire le prompt
        system_prompt = request.system_role or "You are a helpful assistant."
        conversation = "\n".join([f"{msg.role}: {msg.content}" for msg in request.messages])
        
        # Simulation de réponse (remplacer par appel réel à MistralAI)
        response_text = f"Réponse simulée pour: {request.messages[-1].content}"
        
        return ChatResponse(
            response=response_text,
            model=request.model,
            usage={"prompt_tokens": 100, "completion_tokens": 50},
            timestamp=datetime.now().isoformat()
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/mcp/tools", response_model=ToolResponse)
async def execute_tool(request: ToolRequest):
    """
    Exécute un outil d'analyse (concentration, prédiction de réussite, etc.)
    """
    try:
        tool_name = request.tool_name
        parameters = request.parameters
        
        if tool_name == "analyze_concentration":
            result = analyze_concentration(parameters)
        elif tool_name == "predict_success":
            result = predict_success(parameters)
        else:
            raise HTTPException(
                status_code=400,
                detail=f"Outil '{tool_name}' non reconnu. Outils disponibles: analyze_concentration, predict_success"
            )
        
        return ToolResponse(
            result=result,
            tool_name=tool_name,
            timestamp=datetime.now().isoformat()
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/mcp/rag", response_model=RAGResponse)
async def rag_search(request: RAGRequest):
    """
    Recherche dans la base de connaissances (RAG)
    """
    try:
        query = request.query.lower()
        max_results = request.max_results or 3
        
        results = []
        for doc in KNOWLEDGE_BASE:
            score = 0
            query_words = query.split()
            
            title = doc["title"].lower()
            content = doc["content"].lower()
            
            for word in query_words:
                if word in title:
                    score += 3
                if word in content:
                    score += 1
            
            if score > 0:
                results.append({
                    **doc,
                    "relevance_score": score
                })
        
        # Trier par score
        results.sort(key=lambda x: x["relevance_score"], reverse=True)
        results = results[:max_results]
        
        # Retirer le score de pertinence du résultat final
        for result in results:
            result.pop("relevance_score", None)
        
        return RAGResponse(
            results=results,
            query=request.query,
            timestamp=datetime.now().isoformat()
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/mcp/tools/list")
async def list_tools():
    """Liste tous les outils disponibles"""
    return {
        "tools": [
            {
                "name": "analyze_concentration",
                "description": "Analyse le taux de concentration en classe",
                "parameters": {
                    "total_students": "int (requis)",
                    "present_students": "int (requis)",
                    "active_participants": "int",
                    "average_quiz_score": "float",
                    "attention_duration": "int (minutes)"
                }
            },
            {
                "name": "predict_success",
                "description": "Prédit la réussite académique",
                "parameters": {
                    "absences": "int (requis)",
                    "total_sessions": "int (requis)",
                    "grades": "list[float]",
                    "current_average": "float"
                }
            }
        ]
    }

# ==================== DEEP LEARNING ENDPOINTS ====================

@app.post("/dl/predict")
async def deep_learning_predict(file: bytes = Body(...), model_type: str = "pneumonia"):
    """
    Endpoint pour les prédictions Deep Learning (images)
    Supporte: pneumonia, fruits
    """
    # TODO: Intégrer vos modèles de deep learning
    # Exemple avec TensorFlow/PyTorch
    
    return {
        "prediction": "normal",  # ou "pneumonia", "apple", etc.
        "confidence": 0.95,
        "model_type": model_type,
        "timestamp": datetime.now().isoformat()
    }

# ==================== LANCEMENT DU SERVEUR ====================

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True  # Mode développement
    )

