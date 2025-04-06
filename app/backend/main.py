from fastapi import FastAPI
import requests
import psycopg2
import os
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer

app = FastAPI()

DB_CONFIG = {
    "host": os.getenv("DB_HOST"),
    "port": int(os.getenv("DB_PORT", 5432)),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "database": os.getenv("DB_NAME")
}

embedding_model = SentenceTransformer('all-MiniLM-L6-v2')

class ChatRequest(BaseModel):
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
        "enable_ldap": False,  # Виправили false на False
        "enable_signup": True,  # Виправили true на True
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

@app.post("/api/chat")
async def chat(request: ChatRequest):
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()

    try:
        query_embedding = embedding_model.encode(request.prompt).tolist()

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

        response_embedding = embedding_model.encode(ollama_response).tolist()

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