#!/bin/bash

# Docker Run Script for Meta-Analysis MVP
# This script runs the Docker container with proper configurations

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🚀 Starting Meta-Analysis MVP Container..."
echo "=========================================="

# Configuration
IMAGE_NAME="meta-analysis-mvp"
CONTAINER_NAME="meta-analysis-mvp"
TAG=${TAG:-latest}
PORT=${PORT:-3000}
INTERACTIVE=${INTERACTIVE:-true}

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker daemon is not running. Please start Docker.${NC}"
    exit 1
fi

# Check if image exists
if ! docker image inspect "${IMAGE_NAME}:${TAG}" &> /dev/null; then
    echo -e "${YELLOW}⚠️  Image ${IMAGE_NAME}:${TAG} not found. Building it now...${NC}"
    ./docker-build.sh
fi

# Stop existing container if running
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}🛑 Stopping existing container...${NC}"
    docker stop "${CONTAINER_NAME}" 2>/dev/null || true
    docker rm "${CONTAINER_NAME}" 2>/dev/null || true
fi

# Create sessions directory if it doesn't exist
mkdir -p sessions

# Prepare run command
RUN_CMD="docker run"

# Add interactive flags if needed
if [ "$INTERACTIVE" = "true" ]; then
    RUN_CMD="$RUN_CMD -it"
fi

# Build the full docker run command
RUN_CMD="$RUN_CMD \
    --name ${CONTAINER_NAME} \
    --rm \
    -p ${PORT}:3000 \
    -v $(pwd)/sessions:/app/sessions \
    -v $(pwd)/test-data:/app/test-data:ro \
    -e NODE_ENV=production \
    -e SESSIONS_DIR=/app/sessions \
    -e SCRIPTS_DIR=/app/scripts \
    --memory=4g \
    --cpus=2 \
    --security-opt no-new-privileges:true \
    ${IMAGE_NAME}:${TAG}"

echo -e "${BLUE}📋 Container Configuration:${NC}"
echo "   • Image: ${IMAGE_NAME}:${TAG}"
echo "   • Port: ${PORT}:3000"
echo "   • Sessions: $(pwd)/sessions → /app/sessions"
echo "   • Test Data: $(pwd)/test-data → /app/test-data (read-only)"
echo "   • Memory Limit: 4GB"
echo "   • CPU Limit: 2 cores"
echo ""

echo -e "${GREEN}▶️  Starting container...${NC}"
echo ""

# Run the container
eval $RUN_CMD

# This will only execute if container exits
echo ""
echo -e "${YELLOW}📊 Container stopped.${NC}"
