# Local LLM and environment
- Ollama and llama.cpp are installed locally.
- llama.cpp OpenAI-compatible base URL: `http://localhost:9931/v1`.
- NOTE: the original rule also stated llama.cpp "uses port 8080". It conflicts with 9931; verify which one is live (`lsof -i :8080 -i :9931`) and keep one. Read the URL from `.env` (`LLM_BASE_URL`), never hard-code it.
