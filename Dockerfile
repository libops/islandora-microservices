FROM ollama/ollama:0.6.3@sha256:de0786b654561830021475310d61df8073797e917d006a8c6372c8548efc639b

ARG MODEL gemma3:4b
ENV OLLAMA_HOST=0.0.0.0:8080 \
    OLLAMA_MODELS=/models \
    OLLAMA_DEBUG=false \
    OLLAMA_KEEP_ALIVE=-1

RUN ollama serve & sleep 5 && ollama pull $MODEL

ENTRYPOINT ["ollama", "serve"]
