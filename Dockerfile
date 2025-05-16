FROM ollama/ollama:0.7.0@sha256:f6699242880c38eb356dfd8204b08b7a7ba4da2645bdece55a0871bf6752a585

ARG MODEL gemma3:4b
ENV OLLAMA_HOST=0.0.0.0:8080 \
    OLLAMA_MODELS=/models \
    OLLAMA_DEBUG=false \
    OLLAMA_KEEP_ALIVE=-1

RUN ollama serve & sleep 5 && ollama pull $MODEL

ENTRYPOINT ["ollama", "serve"]
