#!/bin/bash

# Smart Mirror Setup Script for Raspberry Pi
# This script automates the installation and setup of the Smart Mirror LLM Agent Service

set -e

echo "🚀 Starting Smart Mirror setup for Raspberry Pi..."

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    echo "⚠️  Warning: This doesn't appear to be a Raspberry Pi. Continuing anyway..."
fi

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install dependencies
echo "🐍 Installing Python and system dependencies..."
sudo apt install python3 python3-pip python3-venv git curl -y

# Install Ollama
echo "🤖 Installing Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh

# Clone repository (if not already cloned)
if [ ! -d "smart_mirror" ]; then
    echo "📥 Cloning repository..."
    git clone https://github.com/your-username/smart_mirror.git
fi

cd smart_mirror

# Set up Python virtual environment
echo "🔧 Setting up Python virtual environment..."
python3 -m venv .venv
source .venv/bin/activate

# Install Python dependencies
echo "📚 Installing Python dependencies..."
pip install -r requirements.txt

# Pull Ollama model (choose based on Pi model)
PI_MODEL=$(cat /proc/device-tree/model | cut -d' ' -f3)
if [[ $PI_MODEL == "5" ]]; then
    echo "🧠 Pulling Llama 3.1 8B model (Pi 5)..."
    ollama pull llama3.1:8b
else
    echo "🧠 Pulling Llama 3.2 3B model (Pi 4 or older)..."
    ollama pull llama3.2:3b
fi

# Configure environment
echo "⚙️  Configuring environment..."
if [ ! -f ".env" ]; then
    cp .env.example .env
    # Update .env for Ollama
    sed -i 's/LLM_PROVIDER=.*/LLM_PROVIDER=ollama/' .env
    if [[ $PI_MODEL == "5" ]]; then
        sed -i 's/LLM_MODEL=.*/LLM_MODEL=llama3.1:8b/' .env
    else
        sed -i 's/LLM_MODEL=.*/LLM_MODEL=llama3.2:3b/' .env
    fi
fi

# Create systemd service
echo "🔄 Creating systemd service..."
sudo tee /etc/systemd/system/smart-mirror.service > /dev/null <<EOF
[Unit]
Description=Smart Mirror LLM Agent Service
After=network.target ollama.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
echo "▶️  Enabling and starting service..."
sudo systemctl daemon-reload
sudo systemctl enable smart-mirror
sudo systemctl start smart-mirror

# Wait a moment for service to start
sleep 5

# Test service
echo "🧪 Testing service..."
if curl -s http://localhost:8000/health | grep -q "ok"; then
    echo "✅ Service is running successfully!"
    echo "🌐 API available at: http://$(hostname -I | awk '{print $1}'):8000"
    echo "📖 Check status: sudo systemctl status smart-mirror"
    echo "📝 View logs: sudo journalctl -u smart-mirror -f"
else
    echo "❌ Service test failed. Check logs with: sudo journalctl -u smart-mirror"
fi

echo "🎉 Setup complete! Your smart mirror backend is ready."