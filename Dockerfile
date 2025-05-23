FROM ollama/ollama:0.7.1@sha256:de659b95818c5ea17dc287a2e4f147f81e202d84f1dc4ad3f256c53fb81e8dd0

ARG MODEL gemma3:4b
ENV OLLAMA_HOST=0.0.0.0:8080 \
    OLLAMA_MODELS=/models \
    OLLAMA_DEBUG=false \
    OLLAMA_KEEP_ALIVE=-1

RUN ollama serve & sleep 5 && ollama pull $MODEL

ENTRYPOINT ["ollama", "serve"]
