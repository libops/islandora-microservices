FROM ollama/ollama:0.11.3@sha256:faa2d82a570de80e6f1b70a7e6669c296f315db558b1a593b79a11162f8ba009

ENV \
  OLLAMA_HOST=0.0.0.0:8080 \
  OLLAMA_MODELS=/models \
  OLLAMA_DEBUG=false \
  OLLAMA_KEEP_ALIVE=-1

RUN ollama serve & sleep 5 && ollama pull gpt-oss:20b

ENTRYPOINT ["ollama", "serve"]
