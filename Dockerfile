FROM ollama/ollama:0.9.5@sha256:64fcc2a7c48ae920f5317264031d86414e30417269631822858c6d23f61100b0

ARG MODEL gemma3:4b
ENV OLLAMA_HOST=0.0.0.0:8080 \
    OLLAMA_MODELS=/models \
    OLLAMA_DEBUG=false \
    OLLAMA_KEEP_ALIVE=-1

RUN ollama serve & sleep 5 && ollama pull $MODEL

ENTRYPOINT ["ollama", "serve"]
