from fastapi import FastAPI
import requests
import psycopg2
import os
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer
from datetime import datetime

app = FastAPI()

DB_CONFIG = {
    "host": os.getenv("DB_HOST"),
    "port": int(os.getenv("DB_PORT", 5432)),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "database": os.getenv("DB_NAME")
}

# Відкладаємо ініціалізацію моделі до першого використання
embedding_model = None

def get_embedding_model():
    global embedding_model
    if embedding_model is None:
        embedding_model = SentenceTransformer('all-MiniLM-L6-v2')
    return embedding_model

class Message(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    model: str
    messages: list[Message]
    stream: bool = False

class ChatRequestLegacy(BaseModel):
    prompt: str

@app.get("/health")
async def health_check():
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        conn.close()
        return {"status": "ok"}
    except Exception as e:
        return {"status": "error", "detail": str(e)}

@app.get("/api/config")
async def get_config():
    return {
        "models": [
            {
                "id": "llama3",
                "name": "LLaMA 3",
                "description": "Meta's LLaMA 3 model"
            }
        ],
        "default_model": "llama3",
        "enable_ldap": False,
        "enable_signup": True,
        "enable_login_form": False,  # Додаємо, щоб OpenWebUI знав, що логін-форма не потрібна
        "enable_oauth_signup": False,  # Додаємо для повноти конфігурації
        "enable_web_search": False,
        "enable_community_sharing": False,
        "enable_ollama": True,
        "ollama_url": "http://chat-cluster-ollama-service:11434",
        "default_locale": "en",
        "default_prompt_suggestions": [
            "What is the capital of France?",
            "Tell me a joke",
            "Explain quantum physics in simple terms"
        ]
    }

@app.post("/api/chat/completions")
async def chat_completions(request: ChatRequest):
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()

    try:
        # Отримуємо останнє повідомлення користувача
        user_message = next((msg.content for msg in request.messages if msg.role == "user"), "")
        if not user_message:
            return {"error": "No user message found in the request"}

        model = get_embedding_model()
        query_embedding = model.encode(user_message).tolist()

        cursor.execute(
            "SELECT message, response FROM messages ORDER BY embedding <-> %s LIMIT 1",
            (query_embedding,)
        )
        similar = cursor.fetchone()
        context = similar[1] if similar else ""

        try:
            response = requests.post(
                "http://chat-cluster-ollama-service:11434/api/generate",
                json={
                    "model": "llama3",
                    "prompt": f"Context: {context}\n\nUser: {user_message}",
                    "stream": False
                }
            )
            response.raise_for_status()
            ollama_response = response.json().get("response", "")
        except requests.RequestException as e:
            return {"error": f"Failed to get response from Ollama: {str(e)}"}

        response_embedding = model.encode(ollama_response).tolist()

        cursor.execute(
            "INSERT INTO messages (message, response, embedding) VALUES (%s, %s, %s)",
            (user_message, ollama_response, response_embedding)
        )
        conn.commit()

        # Повертаємо відповідь у форматі OpenAI API
        return {
            "id": "chatcmpl-" + str(id(request)),
            "object": "chat.completion",
            "created": int(datetime.now().timestamp()),
            "model": request.model,
            "choices": [
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": ollama_response
                    },
                    "finish_reason": "stop"
                }
            ],
            "usage": {
                "prompt_tokens": len(user_message.split()),
                "completion_tokens": len(ollama_response.split()),
                "total_tokens": len(user_message.split()) + len(ollama_response.split())
            }
        }
    except Exception as e:
        return {"error": str(e)}
    finally:
        cursor.close()
        conn.close()

@app.post("/api/chat")
async def chat(request: ChatRequestLegacy):
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()

    try:
        model = get_embedding_model()
        query_embedding = model.encode(request.prompt).tolist()

        cursor.execute(
            "SELECT message, response FROM messages ORDER BY embedding <-> %s LIMIT 1",
            (query_embedding,)
        )
        similar = cursor.fetchone()
        context = similar[1] if similar else ""

        try:
            response = requests.post(
                "http://chat-cluster-ollama-service:11434/api/generate",
                json={
                    "model": "llama3",
                    "prompt": f"Context: {context}\n\nUser: {request.prompt}",
                    "stream": False
                }
            )
            response.raise_for_status()
            ollama_response = response.json().get("response", "")
        except requests.RequestException as e:
            return {"error": f"Failed to get response from Ollama: {str(e)}"}

        response_embedding = model.encode(ollama_response).tolist()

        cursor.execute(
            "INSERT INTO messages (message, response, embedding) VALUES (%s, %s, %s)",
            (request.prompt, ollama_response, response_embedding)
        )
        conn.commit()

        return {"response": ollama_response}
    except Exception as e:
        return {"error": str(e)}
    finally:
        cursor.close()
        conn.close()