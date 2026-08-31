#!/usr/bin/env python3
import subprocess
import json
import time
import sys

OLLAMA_URL = "http://127.0.0.1:11434"
VLLM_URL = "http://127.0.0.1:18080"

prompts = [
    "Write a Python prime checker function",
    "Explain JavaScript closures with code",
    "SQL query for second highest salary",
    "Refactor: const f=(a,b)=>{let r=[];for(let i=0;i<a.length;i++){if(a[i]>b)r.push(a[i])}return r}",
    "Email validation regex explanation"
]

def test_service(url, endpoint):
    try:
        subprocess.run(["curl", "-s", f"{url}{endpoint}"],
                      capture_output=True, timeout=2, check=False)
        return True
    except:
        return False

print("Checking services...")
if not test_service(OLLAMA_URL, "/api/tags"):
    print("❌ Ollama offline")
    sys.exit(1)
if not test_service(VLLM_URL, "/v1/models"):
    print("❌ vLLM offline")
    sys.exit(1)

print("✅ Services online\n")

for i, prompt in enumerate(prompts, 1):
    print(f"[{i}/5] {prompt[:50]}...")

    # Ollama
    ollama_data = json.dumps({
        "model": "qwen2.5-coder:7b",
        "messages": [{"role": "user", "content": prompt}],
        "stream": False
    })
    start = time.time() * 1000
    try:
        result = subprocess.run(
            ["curl", "-s", f"{OLLAMA_URL}/api/chat",
             "-H", "Content-Type: application/json",
             "-d", ollama_data],
            capture_output=True, timeout=30, text=True
        )
        elapsed = time.time() * 1000 - start
        resp = json.loads(result.stdout)
        tokens = resp.get("eval_count", 0)
        if tokens > 0:
            print(f"  Ollama: {tokens} tokens in {elapsed:.0f}ms")
        else:
            print("  Ollama: ❌")
    except Exception as e:
        print(f"  Ollama: ❌ {e}")

    # vLLM
    vllm_data = json.dumps({
        "model": "Qwen/Qwen2.5-Coder-7B-Instruct",
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0,
        "max_tokens": 2048
    })
    start = time.time() * 1000
    try:
        result = subprocess.run(
            ["curl", "-s", f"{VLLM_URL}/v1/chat/completions",
             "-H", "Content-Type: application/json",
             "-d", vllm_data],
            capture_output=True, timeout=30, text=True
        )
        elapsed = time.time() * 1000 - start
        resp = json.loads(result.stdout)
        tokens = resp.get("usage", {}).get("completion_tokens", 0)
        if tokens > 0:
            print(f"  vLLM: {tokens} tokens in {elapsed:.0f}ms")
        else:
            print("  vLLM: ❌")
    except Exception as e:
        print(f"  vLLM: ❌ {e}")

print("\nDone!")
