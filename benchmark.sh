#!/bin/bash

OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"
VLLM_URL="${VLLM_URL:-http://127.0.0.1:18080}"

echo "Checking services..."
if ! curl -s "${OLLAMA_URL}/api/tags" > /dev/null 2>&1; then
  echo "❌ Ollama not responding at ${OLLAMA_URL}"
  exit 1
fi

if ! curl -s "${VLLM_URL}/v1/models" > /dev/null 2>&1; then
  echo "❌ vLLM not responding at ${VLLM_URL}"
  exit 1
fi

echo "✅ Services online"

PROMPTS=(
  "Write a Python function to check if a number is prime."
  "Explain JavaScript closures with a code example."
  "SQL query for second highest salary per department."
  "Refactor: const f=(a,b)=>{let r=[];for(let i=0;i<a.length;i++){if(a[i]>b)r.push(a[i])}return r}"
  "Write regex to validate email addresses."
)

echo ""
echo "========== BENCHMARK =========="

for i in "${!PROMPTS[@]}"; do
  PROMPT="${PROMPTS[$i]}"
  echo ""
  echo "[$((i+1))/5] ${PROMPT:0:60}..."

  # Ollama - proper JSON escaping
  START=$(date +%s%N)
  OLLAMA_JSON=$(python3 -c "import json; print(json.dumps({'model':'qwen2.5-coder:7b','messages':[{'role':'user','content':'$PROMPT'}],'stream':False}))")
  OLLAMA_RESPONSE=$(curl -s "${OLLAMA_URL}/api/chat" \
    -H "Content-Type: application/json" \
    -d "$OLLAMA_JSON" 2>/dev/null)
  END=$(date +%s%N)

  OLLAMA_TIME=$((($END - $START) / 1000000))
  OLLAMA_TIME_SEC=$(awk "BEGIN {printf \"%.2f\", $OLLAMA_TIME / 1000}")
  OLLAMA_TOKENS=$(echo "$OLLAMA_RESPONSE" | python3 -c "import json,sys; print(json.load(sys.stdin).get('eval_count',0))" 2>/dev/null || echo "0")

  if [ "$OLLAMA_TOKENS" != "0" ] && [ ! -z "$OLLAMA_TIME_SEC" ]; then
    OLLAMA_TPS=$(awk "BEGIN {printf \"%.1f\", $OLLAMA_TOKENS / ($OLLAMA_TIME_SEC)}")
    echo "  Ollama: $OLLAMA_TOKENS tokens in ${OLLAMA_TIME_SEC}s ($OLLAMA_TPS tok/s)"
  else
    echo "  Ollama: ❌ Error"
  fi

  # vLLM - proper JSON escaping
  START=$(date +%s%N)
  VLLM_JSON=$(python3 -c "import json; print(json.dumps({'model':'Qwen/Qwen2.5-Coder-7B-Instruct','messages':[{'role':'user','content':'$PROMPT'}],'temperature':0,'max_tokens':2048}))")
  VLLM_RESPONSE=$(curl -s "${VLLM_URL}/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d "$VLLM_JSON" 2>/dev/null)
  END=$(date +%s%N)

  VLLM_TIME=$((($END - $START) / 1000000))
  VLLM_TIME_SEC=$(awk "BEGIN {printf \"%.2f\", $VLLM_TIME / 1000}")
  VLLM_TOKENS=$(echo "$VLLM_RESPONSE" | python3 -c "import json,sys; print(json.load(sys.stdin).get('usage',{}).get('completion_tokens',0))" 2>/dev/null || echo "0")

  if [ "$VLLM_TOKENS" != "0" ] && [ ! -z "$VLLM_TIME_SEC" ]; then
    VLLM_TPS=$(awk "BEGIN {printf \"%.1f\", $VLLM_TOKENS / ($VLLM_TIME_SEC)}")
    echo "  vLLM:   $VLLM_TOKENS tokens in ${VLLM_TIME_SEC}s ($VLLM_TPS tok/s)"
  else
    echo "  vLLM:   ❌ Error"
  fi
done

echo ""
echo "Done!"
