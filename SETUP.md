# Open WebUI Setup with Auto Tool Choice

## Problem
Open WebUI was showing an error:
```
"auto" tool choice requires --enable-auto-tool-choice and --tool-call-parser to be set
```

## Solution
This repository contains a properly configured `docker-compose.yml` that enables auto tool choice for Open WebUI.

## Key Configuration
The fix involves two environment variables:
- `ENABLE_AUTO_TOOL_CHOICE=true` - Enables automatic tool selection
- `TOOL_CALL_PARSER=function_calls` - Specifies how to parse tool calls

## Quick Start

### Option 1: Automated Setup (Recommended)
```bash
cd /home/user/Reasonix-coding-agent
chmod +x setup.sh
./setup.sh
```

### Option 2: Manual Docker Compose
```bash
cd /home/user/Reasonix-coding-agent
docker-compose up -d
```

### Option 3: Using .env file
1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Modify `.env` if needed (optional)

3. Start services:
   ```bash
   docker-compose up -d
   ```

## Verify Setup
1. Open WebUI should be accessible at: `http://localhost:3000`
2. The error about auto tool choice should no longer appear
3. Models should now support automatic tool selection

## Files
- `docker-compose.yml` - Complete Docker Compose configuration
- `setup.sh` - Automated setup script
- `.env.example` - Environment variable template
- `SETUP.md` - This file

## Troubleshooting

### Check if services are running
```bash
docker-compose ps
```

### View logs
```bash
docker-compose logs -f open-webui
```

### Stop services
```bash
docker-compose down
```

### Complete reset
```bash
docker-compose down -v
./setup.sh
```

## Services Included
- **open-webui** - Web interface on port 3000
- **ollama** - LLM backend on port 11434

## Next Steps
1. Create an admin account (first run)
2. Configure models
3. Start chatting with auto tool choice enabled!

---

**Status**: ✅ Configuration complete with auto tool choice enabled
