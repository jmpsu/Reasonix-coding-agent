#!/bin/bash

set -e

echo "🚀 Setting up Open WebUI with auto tool choice enabled..."

# Copy .env.example to .env if it doesn't exist
if [ ! -f .env ]; then
    cp .env.example .env
    echo "✅ Created .env file from template"
fi

# Check if Docker and Docker Compose are installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Stop existing containers if running
echo "Stopping any existing Open WebUI containers..."
docker-compose down 2>/dev/null || true

# Build and start containers
echo "Building and starting services..."
docker-compose up -d

echo ""
echo "✅ Open WebUI is starting..."
echo ""
echo "🌐 Access Open WebUI at: http://localhost:3000"
echo ""
echo "⚙️  Configuration:"
echo "   - ENABLE_AUTO_TOOL_CHOICE=true"
echo "   - TOOL_CALL_PARSER=function_calls"
echo ""
echo "📋 View logs with: docker-compose logs -f open-webui"
echo ""
