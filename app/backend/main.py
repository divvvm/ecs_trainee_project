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

class ChatRequestLegacy(BaseModel):
    prompt: str

class UserSignup(BaseModel):
    email: EmailStr
    password: str

class UserSignin(BaseModel):
    email: EmailStr
    password: str

@app.get("/api/v1/tools/")
async def get_tools():
    tools = [{"id": 1, "name": "Default Tool", "active": True}]
    return tools

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
        "auth_enabled": True,
        "features": {
            "enable_login_form": True,
            "enable_signup": True,
            "enable_ldap": False,
            "enable_oauth_signup": False,
            "enable_community_sharing": False,
            "enable_web_search": False,
            "enable_ollama": True,
        },
        "models": [
            {
                "id": "llama3",
                "name": "LLaMA 3",
                "description": "Meta's LLaMA 3 model"
            }
        ],
        "default_model": "llama3",
        "ollama_url": "http://chat-cluster-ollama-service:11434",
        "default_locale": "en",
        "default_prompt_suggestions": [
            "What is the capital of France?",
            "Tell me a joke",
            "Explain quantum physics in simple terms"
        ]
    }

@app.post("/api/v1/auths/signup")
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

@app.post("/api/v1/auths/signin")
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
            "user": {
                "id": result[0],
                "email": user.email
            }
        }
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)
    finally:
        cursor.close()
        conn.close()

@app.get("/api/changelog")
async def changelog():
    return []

@app.post("/api/chat/completions")
async def chat_completions(request: ChatRequest):
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()
    try:
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
        response_embedding = model.encode(ollama_response).tolist()
        cursor.execute(
            "INSERT INTO messages (message, response, embedding) VALUES (%s, %s, %s)",
            (user_message, ollama_response, response_embedding)
        )
        conn.commit()
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