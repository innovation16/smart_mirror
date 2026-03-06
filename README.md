# Smart Mirror LLM Agent Service (LangGraph + LangChain)

A lightweight Python service that accepts a user prompt and sends it to an LLM through a LangGraph-powered agent.

## What this includes
- FastAPI service with `/chat` endpoint
- LangGraph agent with short-term memory by `thread_id`
- LangChain model integration (default provider: local Ollama)
- Optional MCP tool integration (via `langchain-mcp-adapters`)

## Quick start

### General Setup (Mac/Windows/Linux)

### 1) Install dependencies
```bash
mac: python3 -m venv .venv
windows: check environment variable

mac: source .venv/bin/activate
windows: .venv\bin\activate.ps1

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

### Raspberry Pi Setup

For running on a Raspberry Pi-powered smart mirror:

#### Prerequisites
- Raspberry Pi 4 or 5 (recommended for better performance with LLMs)
- At least 4GB RAM (8GB recommended for larger models)
- Raspberry Pi OS (64-bit) installed
- Internet connection for initial setup
- MicroSD card with at least 16GB storage

#### Automated Setup (Recommended)
Run the automated setup script:
```bash
wget https://raw.githubusercontent.com/your-username/smart_mirror/main/setup_pi.sh
chmod +x setup_pi.sh
./setup_pi.sh
```

This will:
- Update system packages
- Install Python, Ollama, and dependencies
- Set up the service with auto-start
- Test the installation

#### Manual Setup

#### 1) Update system and install dependencies
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install python3 python3-pip python3-venv git -y
```

#### 2) Clone the repository
```bash
git clone https://github.com/your-username/smart_mirror.git
cd smart_mirror
```

#### 3) Set up Python virtual environment
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

#### 4) Install Ollama
```bash
curl -fsSL https://ollama.ai/install.sh | sh
```

#### 5) Pull a lightweight model (adjust based on Pi capabilities)
For Pi 4: Use smaller models to avoid memory issues
```bash
ollama pull llama3.2:1b  # Very lightweight
# or
ollama pull llama3.2:3b  # Balanced performance
```

For Pi 5: Can handle larger models
```bash
ollama pull llama3.1:8b
```

#### 6) Configure environment
```bash
cp .env.example .env
# Edit .env to set LLM_PROVIDER=ollama and appropriate model
nano .env
```

#### 7) Test the service
```bash
source .venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

#### 8) Set up auto-start on boot (optional)
Create a systemd service:
```bash
sudo nano /etc/systemd/system/smart-mirror.service
```

Add the following content:
```
[Unit]
Description=Smart Mirror LLM Agent Service
After=network.target ollama.service

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/smart_mirror
ExecStart=/home/pi/smart_mirror/.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enable and start the service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable smart-mirror
sudo systemctl start smart-mirror
```

Check status:
```bash
sudo systemctl status smart-mirror
```

#### 9) Integrate with mirror display
This service provides the backend API. For the full smart mirror experience, you'll need a frontend application that:
- Displays time, weather, calendar
- Provides voice input interface
- Calls this `/chat` endpoint for LLM responses

Popular options include:
- MagicMirror² (https://magicmirror.builders/)
- Custom web app using this API

#### Troubleshooting
- If Ollama fails to start: Ensure sufficient RAM (at least 2GB free for small models)
- Service won't start: Check logs with `sudo journalctl -u smart-mirror`
- Port conflicts: Change port in .env and systemd service
- Performance issues: Use smaller models or add swap space: `sudo dphys-swapfile swapoff && sudo dphys-swapfile swapon`

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
