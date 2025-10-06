#!/usr/bin/env bash
set -euo pipefail

# 1) Launch LiteLLM server (port: 4000)
uv run litellm --config /workspace/litellm_config.yaml --port "${LITELLM_PORT:-4000}" &

# 2) Launch LightRAG server (port: 9621)
uv run lightrag-server
