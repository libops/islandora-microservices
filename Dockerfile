FROM ollama/ollama:0.6.5@sha256:96b7667cb536ab69bfd5cc0c2bd1e29602218e076fe6d34f402b786f17b4fde0

ARG MODEL gemma3:4b
ENV OLLAMA_HOST=0.0.0.0:8080 \
    OLLAMA_MODELS=/models \
    OLLAMA_DEBUG=false \
    OLLAMA_KEEP_ALIVE=-1

RUN ollama serve & sleep 5 && ollama pull $MODEL

ENTRYPOINT ["ollama", "serve"]
