FROM ollama/ollama:0.6.8@sha256:50ab2378567a62b811a2967759dd91f254864c3495cbe50576bd8a85bc6edd56

ARG MODEL gemma3:4b
ENV OLLAMA_HOST=0.0.0.0:8080 \
    OLLAMA_MODELS=/models \
    OLLAMA_DEBUG=false \
    OLLAMA_KEEP_ALIVE=-1

RUN ollama serve & sleep 5 && ollama pull $MODEL

ENTRYPOINT ["ollama", "serve"]
