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

# Clone repository (if not already cloned)
if [ ! -d "smart_mirror" ]; then
    echo "📥 Cloning repository..."
    git clone https://github.com/innovation16/smart_mirror.git
fi

cd smart_mirror

# Set up Python virtual environment (only if not already set up)
if [ ! -d ".venv" ]; then
    echo "🔧 Setting up Python virtual environment..."
    python3 -m venv .venv
fi

source .venv/bin/activate

# Install Python dependencies
echo "📚 Installing Python dependencies..."
pip install -r requirements.txt

# Configure environment
echo "⚙️  Configuring environment..."
cp .env.example .env
sed -i 's/LLM_PROVIDER=.*/LLM_PROVIDER=groq/' .env

if [ -z "$GROQ_API_KEY" ]; then
    echo ""
    echo "⚠️  IMPORTANT: Add your Groq API key to .env"
    echo "Get it from: https://console.groq.com/keys"
    read -p "Enter your Groq API key: " GROQ_KEY
    sed -i "s/GROQ_API_KEY=.*/GROQ_API_KEY=$GROQ_KEY/" .env
else
    sed -i "s/GROQ_API_KEY=.*/GROQ_API_KEY=$GROQ_API_KEY/" .env
fi

# Create systemd service
echo "🔄 Creating systemd service..."
sudo tee /etc/systemd/system/smart-mirror.service > /dev/null <<EOF
[Unit]
Description=Smart Mirror LLM Agent Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
EnvironmentFile=$(pwd)/.env
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
sudo systemctl restart smart-mirror

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