#!/usr/bin/env bash

set -eou pipefail

# thread a script to wait for ollama serve to be ready
# then preload the model
{
    until ollama list > /dev/null 2>&1; do sleep 1; done
    ollama run "$OLLAMA_MODEL" ""
} &

exec ollama serve

