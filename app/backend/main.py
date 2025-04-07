from fastapi import FastAPI
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer
from datetime import datetime
import psycopg2
import requests
import os

app = FastAPI()

DB_CONFIG = {
    "host": os.getenv("DB_HOST"),
    "port": int(os.getenv("DB_PORT", 5432)),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "database": os.getenv("DB_NAME")
}

embedding_model = None

def get_embedding_model():
    global embedding_model
    if embedding_model is None:
        embedding_model = SentenceTransformer('all-MiniLM-L6-v2')
    return embedding_model

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

@app.post("/api/chat")
async def chat(request: ChatRequest):
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()

    try:
        prompt = request.prompt
        if not prompt:
            return {"error": "Prompt is required"}

        model = get_embedding_model()
        query_embedding = model.encode(prompt).tolist()

        cursor.execute(
            "SELECT message, response FROM messages ORDER BY embedding <-> %s LIMIT 1",
            (query_embedding,)
        )
        similar = cursor.fetchone()
        context = similar[1] if similar else ""

        response = requests.post(
            "http://chat-cluster-ollama-service:11434/api/generate",
            json={
                "model": "llama3",
                "prompt": f"Context: {context}\n\nUser: {prompt}",
                "stream": False
            }
        )
        response.raise_for_status()
        ollama_response = response.json().get("response", "")

        response_embedding = model.encode(ollama_response).tolist()

        cursor.execute(
            "INSERT INTO messages (message, response, embedding) VALUES (%s, %s, %s)",
            (prompt, ollama_response, response_embedding)
        )
        conn.commit()

        return {"response": ollama_response}
    except Exception as e:
        return {"error": str(e)}
    finally:
        cursor.close()
        conn.close()
