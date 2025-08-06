FROM ollama/ollama:0.11.0@sha256:c1bc4eb9ba010a710cc6998b0f3510e206c7c0c151ca898cd6f026c02472defc

ENV \
  OLLAMA_HOST=0.0.0.0:8080 \
  OLLAMA_MODELS=/models \
  OLLAMA_DEBUG=false \
  OLLAMA_KEEP_ALIVE=-1

RUN ollama serve & sleep 5 && ollama pull gpt-oss:20b

ENTRYPOINT ["ollama", "serve"]
