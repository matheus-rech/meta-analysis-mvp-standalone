#!/usr/bin/env bash
set -euo pipefail

# Dockerized MCP server runner for Claude Desktop (stdio transport)
# - Uses an image that contains Node + R + required R packages
# - Connects stdin/stdout to the containerized server
# - Mounts a host sessions directory for persistence

IMAGE_NAME="${MCP_IMAGE:-meta-analysis-mvp}"
IMAGE_TAG="${MCP_TAG:-latest}"
IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

# Preconditions
if ! command -v docker >/dev/null 2>&1; then
  echo "[mcp-docker] Docker CLI not found. Please install Docker Desktop or Docker Engine." >&2
  exit 1
fi

# Resolve project root as the directory containing this script's parent
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Sessions directory
HOST_SESSIONS_DIR="${SESSIONS_DIR:-$PROJECT_ROOT/sessions}"
mkdir -p "$HOST_SESSIONS_DIR"

# Ensure image is available: prefer local, then pull, then build
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "[mcp-docker] Image not found: $IMAGE; attempting docker pull..." >&2
  if ! docker pull "$IMAGE" >/dev/null 2>&1; then
    IMAGE_TAG="${MCP_TAG:-latest}"
    echo "[mcp-docker] Pull failed; building image locally as $IMAGE_NAME:$IMAGE_TAG" >&2
    docker build -t "$IMAGE_NAME:$IMAGE_TAG" "$PROJECT_ROOT"
    IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
  fi
fi

# Run container with stdio connected; no TTY
exec docker run --rm -i \
  -v "$HOST_SESSIONS_DIR":/app/sessions \
  -e SESSIONS_DIR=/app/sessions \
  "$IMAGE"
