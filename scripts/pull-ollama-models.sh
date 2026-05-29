#!/bin/sh
# Chạy sau khi docker compose up: sh scripts/pull-ollama-models.sh
docker exec vietai_ollama ollama pull nomic-embed-text
docker exec vietai_ollama ollama pull llama3.1:8b
echo "Models ready."
