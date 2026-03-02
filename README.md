# Smart Mirror LLM Agent Service (LangGraph + LangChain)

A lightweight Python service that accepts a user prompt and sends it to an LLM through a LangGraph-powered agent.

## What this includes
- FastAPI service with `/chat` endpoint
- LangGraph agent with short-term memory by `thread_id`
- LangChain model integration (default provider: local Ollama)
- Optional MCP tool integration (via `langchain-mcp-adapters`)

## Quick start

### 1) Install dependencies
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2) Configure env
```bash
cp .env.example .env
```

### 3) Start a free local model via Ollama
Install Ollama and pull a model:
```bash
ollama pull llama3.1:8b
```

### 4) Run server
```bash
uvicorn app.main:app --reload --port 8000
```

### 5) Test chat
```bash
curl -X POST http://127.0.0.1:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Write a one-line weather greeting.","thread_id":"user-1"}'
```

## API

### `GET /health`
Returns service status.

### `POST /chat`
Request:
```json
{
  "prompt": "Hello, who are you?",
  "thread_id": "user-1"
}
```

Response:
```json
{
  "response": "I am your assistant...",
  "thread_id": "user-1"
}
```

## MCP setup

When MCP is enabled, the agent can call tools exposed by configured MCP servers.

### 1) Enable MCP in `.env`
```dotenv
MCP_ENABLED=true
MCP_SERVERS_JSON=[{"name":"filesystem","transport":"stdio","command":"npx","args":["-y","@modelcontextprotocol/server-filesystem","/tmp"]}]
```

### 2) Restart server
The agent will load tools during startup.

### 3) Prompt with tool intent
Example:
```text
List files in /tmp and summarize what is there.
```

## Architecture
- `app/main.py`: FastAPI entrypoint
- `app/agent.py`: LangGraph agent and tool-calling loop
- `app/mcp_client.py`: MCP tool discovery client
- `app/config.py`: env-driven settings

## Notes
- Default config is fully local (`LLM_PROVIDER=ollama`) to keep cost at zero.
- You can add more providers in `app/agent.py` later (OpenAI, Groq, etc.) while keeping the same API.
