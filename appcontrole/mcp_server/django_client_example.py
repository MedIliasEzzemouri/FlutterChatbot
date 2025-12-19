"""
Exemple de client Django pour consommer le serveur MCP
À intégrer dans votre application Django
"""

import requests
from typing import List, Dict, Any, Optional

class MCPClient:
    """Client pour communiquer avec le serveur MCP"""
    
    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url
    
    def chat(self, messages: List[Dict[str, str]], 
             model: str = "mistral-small",
             temperature: float = 0.7,
             max_tokens: int = 1000) -> Dict[str, Any]:
        """
        Envoie une requête de chat au serveur MCP
        
        Args:
            messages: Liste de messages [{"role": "user", "content": "..."}]
            model: Modèle à utiliser
            temperature: Température pour la génération
            max_tokens: Nombre maximum de tokens
        
        Returns:
            Réponse du serveur MCP
        """
        response = requests.post(
            f"{self.base_url}/mcp/chat",
            json={
                "messages": messages,
                "model": model,
                "temperature": temperature,
                "max_tokens": max_tokens
            }
        )
        response.raise_for_status()
        return response.json()
    
    def rag_search(self, query: str, max_results: int = 3) -> List[Dict[str, str]]:
        """
        Recherche dans la base de connaissances (RAG)
        
        Args:
            query: Requête de recherche
            max_results: Nombre maximum de résultats
        
        Returns:
            Liste de documents pertinents
        """
        response = requests.post(
            f"{self.base_url}/mcp/rag",
            json={
                "query": query,
                "max_results": max_results
            }
        )
        response.raise_for_status()
        return response.json()["results"]
    
    def analyze_concentration(self, total_students: int,
                             present_students: int,
                             active_participants: int,
                             average_quiz_score: float,
                             attention_duration: int) -> Dict[str, Any]:
        """
        Analyse le taux de concentration
        
        Returns:
            Résultats de l'analyse
        """
        response = requests.post(
            f"{self.base_url}/mcp/tools",
            json={
                "tool_name": "analyze_concentration",
                "parameters": {
                    "total_students": total_students,
                    "present_students": present_students,
                    "active_participants": active_participants,
                    "average_quiz_score": average_quiz_score,
                    "attention_duration": attention_duration
                }
            }
        )
        response.raise_for_status()
        return response.json()["result"]
    
    def predict_success(self, absences: int,
                       total_sessions: int,
                       grades: List[float],
                       current_average: float) -> Dict[str, Any]:
        """
        Prédit la réussite académique
        
        Returns:
            Résultats de la prédiction
        """
        response = requests.post(
            f"{self.base_url}/mcp/tools",
            json={
                "tool_name": "predict_success",
                "parameters": {
                    "absences": absences,
                    "total_sessions": total_sessions,
                    "grades": grades,
                    "current_average": current_average
                }
            }
        )
        response.raise_for_status()
        return response.json()["result"]


# ==================== EXEMPLE D'UTILISATION DANS DJANGO ====================

# Dans views.py ou services.py de votre app Django

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json

# Initialiser le client
mcp_client = MCPClient(base_url="http://localhost:8000")

@csrf_exempt
def chat_view(request):
    """Vue Django pour le chat"""
    if request.method == 'POST':
        data = json.loads(request.body)
        messages = data.get('messages', [])
        
        try:
            response = mcp_client.chat(messages=messages)
            return JsonResponse(response)
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)
    
    return JsonResponse({'error': 'Method not allowed'}, status=405)

@csrf_exempt
def analyze_concentration_view(request):
    """Vue Django pour l'analyse de concentration"""
    if request.method == 'POST':
        data = json.loads(request.body)
        
        try:
            result = mcp_client.analyze_concentration(
                total_students=data['total_students'],
                present_students=data['present_students'],
                active_participants=data['active_participants'],
                average_quiz_score=data['average_quiz_score'],
                attention_duration=data['attention_duration']
            )
            return JsonResponse(result)
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)
    
    return JsonResponse({'error': 'Method not allowed'}, status=405)

# ==================== EXEMPLE DANS UN MODÈLE DJANGO ====================

# models.py
from django.db import models

class ChatSession(models.Model):
    user_id = models.IntegerField()
    messages = models.JSONField(default=list)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def add_message(self, role: str, content: str):
        """Ajoute un message à la session"""
        self.messages.append({
            "role": role,
            "content": content
        })
        self.save()
    
    def get_mcp_response(self):
        """Obtient une réponse du serveur MCP"""
        try:
            response = mcp_client.chat(messages=self.messages)
            self.add_message("assistant", response["response"])
            return response["response"]
        except Exception as e:
            return f"Erreur: {str(e)}"

