from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel, EmailStr
from sentence_transformers import SentenceTransformer
from datetime import datetime
import psycopg2
import requests
import os
from passlib.hash import bcrypt

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

class Message(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    model: str
    messages: list[Message]
    stream: bool = False

class UserSignup(BaseModel):
    email: EmailStr
    password: str

class UserSignin(BaseModel):
    email: EmailStr
    password: str

@app.get("/health")
async def health_check():
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        conn.close()
        return {"status": "healthy"}
    except Exception as e:
        return {"status": "error", "detail": str(e)}

@app.post("/v1/auth/signup")
async def signup(user: UserSignup):
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT id FROM users WHERE email = %s", (user.email,))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="User already exists")
        hashed_password = bcrypt.hash(user.password)
        cursor.execute(
            "INSERT INTO users (email, password) VALUES (%s, %s)",
            (user.email, hashed_password)
        )
        conn.commit()
        return JSONResponse(content={"message": "User created successfully"}, status_code=201)
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)
    finally:
        cursor.close()
        conn.close()

@app.post("/v1/auth/signin")
async def signin(user: UserSignin):
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT id, password FROM users WHERE email = %s", (user.email,))
        result = cursor.fetchone()
        if not result or not bcrypt.verify(user.password, result[1]):
            raise HTTPException(status_code=401, detail="Invalid credentials")
        return {
            "access_token": "dummy-token",
            "token_type": "bearer",
            "user": {"id": result[0], "email": user.email}
        }
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)
    finally:
        cursor.close()
        conn.close()

@app.post("/v1/chat/completions")
async def chat_completions(request: ChatRequest):
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()
    try:
        user_message = next((msg.content for msg in request.messages if msg.role == "user"), "")
        if not user_message:
            raise HTTPException(status_code=400, detail="No user message found")

        model = get_embedding_model()
        query_embedding = model.encode(user_message).tolist()

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
                "prompt": f"Context: {context}\n\nUser: {user_message}",
                "stream": request.stream
            }
        )
        response.raise_for_status()
        ollama_response = response.json().get("response", "")

        response_embedding = model.encode(ollama_response).tolist()
        cursor.execute(
            "INSERT INTO messages (message, response, embedding) VALUES (%s, %s, %s)",
            (user_message, ollama_response, response_embedding)
        )
        conn.commit()

        return {
            "id": f"chatcmpl-{id(request)}",
            "object": "chat.completion",
            "created": int(datetime.now().timestamp()),
            "model": request.model,
            "choices": [
                {
                    "index": 0,
                    "message": {"role": "assistant", "content": ollama_response},
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
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()