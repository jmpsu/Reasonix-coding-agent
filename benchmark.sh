#!/bin/bash

set -e

# A/B benchmark: Ollama (11434) vs vLLM (18080)
OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"
VLLM_URL="${VLLM_URL:-http://127.0.0.1:18080}"

echo "Checking services..."
if ! curl -s "${OLLAMA_URL}/api/tags" > /dev/null 2>&1; then
  echo "❌ Ollama not responding at ${OLLAMA_URL}"
  echo "   Start with: ollama serve"
  exit 1
fi

if ! curl -s "${VLLM_URL}/v1/models" > /dev/null 2>&1; then
  echo "❌ vLLM not responding at ${VLLM_URL}"
  echo "   Start with: python -m vllm.entrypoints.openai.api_server --model Qwen/Qwen2.5-Coder-7B-Instruct"
  exit 1
fi

echo "✅ Both services online"
echo ""

PROMPTS=(
  "Write a Python function to check if a number is prime. Include docstring."
  "Explain how JavaScript closures work with a code example."
  "Write a SQL query to find the second highest salary in each department."
  "Refactor this code to be more readable: const f=(a,b)=>{let r=[];for(let i=0;i<a.length;i++){if(a[i]>b)r.push(a[i])}return r}"
  "Write a regex to validate email addresses and explain each part."
)

echo "================================================="
echo "  A/B BENCHMARK: Ollama vs vLLM"
echo "  Ollama: ${OLLAMA_URL}"
echo "  vLLM: ${VLLM_URL}"
echo "  Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "================================================="

for i in "${!PROMPTS[@]}"; do
  PROMPT="${PROMPTS[$i]}"
  echo ""
  echo "--- Prompt $((i+1))/${#PROMPTS[@]} ---"
  echo "Query: ${PROMPT:0:70}..."
  echo ""

  # Ollama
  echo -n "Ollama: "
  START=$(date +%s%N)
  OLLAMA_RESPONSE=$(curl -s "${OLLAMA_URL}/api/chat" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"qwen2.5-coder:7b\",\"messages\":[{\"role\":\"user\",\"content\":\"$PROMPT\"}],\"stream\":false}")
  END=$(date +%s%N)
  OLLAMA_TIME=$(echo "scale=3; ($END - $START) / 1000000000" | bc)

  OLLAMA_TOKENS=$(echo "$OLLAMA_RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('eval_count',0))" 2>/dev/null || echo "0")
  OLLAMA_TEXT=$(echo "$OLLAMA_RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('message',{}).get('content','')[:100])" 2>/dev/null || echo "")

  if [ "$OLLAMA_TOKENS" != "0" ]; then
    OLLAMA_TPS=$(echo "scale=2; $OLLAMA_TOKENS / $OLLAMA_TIME" | bc)
    echo "$OLLAMA_TOKENS tokens in ${OLLAMA_TIME}s (${OLLAMA_TPS} tok/s)"
  else
    echo "⚠️  No response or parsing error"
  fi

  # vLLM
  echo -n "vLLM:   "
  START=$(date +%s%N)
  VLLM_RESPONSE=$(curl -s "${VLLM_URL}/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"Qwen/Qwen2.5-Coder-7B-Instruct\",\"messages\":[{\"role\":\"user\",\"content\":\"$PROMPT\"}],\"temperature\":0,\"max_tokens\":2048}")
  END=$(date +%s%N)
  VLLM_TIME=$(echo "scale=3; ($END - $START) / 1000000000" | bc)

  VLLM_TOKENS=$(echo "$VLLM_RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('usage',{}).get('completion_tokens',0))" 2>/dev/null || echo "0")
  VLLM_TEXT=$(echo "$VLLM_RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('choices',[{}])[0].get('message',{}).get('content','')[:100])" 2>/dev/null || echo "")

  if [ "$VLLM_TOKENS" != "0" ]; then
    VLLM_TPS=$(echo "scale=2; $VLLM_TOKENS / $VLLM_TIME" | bc)
    echo "$VLLM_TOKENS tokens in ${VLLM_TIME}s (${VLLM_TPS} tok/s)"
  else
    echo "⚠️  No response or parsing error"
  fi

  echo ""
done

echo "================================================="
if command -v nvidia-smi &> /dev/null; then
  echo "GPU Status:"
  nvidia-smi --query-gpu=memory.used,memory.free,utilization.gpu,temperature.gpu --format=csv,noheader
else
  echo "GPU monitoring not available on this system"
fi
