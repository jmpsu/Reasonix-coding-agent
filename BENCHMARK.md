# Ollama vs vLLM Benchmark

Compare performance of Ollama and vLLM with Qwen2.5-Coder-7B model.

## Prerequisites

### Ollama
```bash
# Install
curl -fsSL https://ollama.ai/install.sh | sh

# Pull model
ollama pull qwen2.5-coder:7b

# Start server (in separate terminal)
ollama serve
```

### vLLM
```bash
# Install
pip install vllm

# Start server (in separate terminal)
python -m vllm.entrypoints.openai.api_server \
  --model Qwen/Qwen2.5-Coder-7B-Instruct \
  --port 18080
```

## Usage

```bash
# Default (127.0.0.1:11434 for Ollama, 127.0.0.1:18080 for vLLM)
./benchmark.sh

# Custom URLs
OLLAMA_URL=http://192.168.1.100:11434 \
VLLM_URL=http://192.168.1.100:18080 \
./benchmark.sh
```

## Output

Shows for each prompt:
- Tokens generated
- Time taken
- Tokens per second (throughput)

## Metrics

- **Tokens**: Number of tokens generated
- **Time**: Total API response time
- **Tok/s**: Throughput (tokens per second)

Higher throughput = faster model

## Notes

- Both services must be running
- Uses `qwen2.5-coder:7b` for Ollama
- Uses `Qwen/Qwen2.5-Coder-7B-Instruct` for vLLM
- Temperature set to 0 for consistency
