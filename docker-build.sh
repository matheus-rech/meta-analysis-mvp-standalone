#!/bin/bash

# Docker Build Script for Meta-Analysis MVP
# This script builds the Docker image with optimizations

set -e  # Exit on error

echo "🔨 Building Meta-Analysis MVP Docker Image..."
echo "============================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker daemon is not running. Please start Docker.${NC}"
    exit 1
fi

# Build TypeScript first (if not already built)
if [ ! -d "build" ]; then
    echo -e "${YELLOW}📦 Building TypeScript files...${NC}"
    npm run build
fi

# Create sessions directory if it doesn't exist
mkdir -p sessions

# Build options
BUILD_CACHE=${USE_CACHE:-true}
BUILD_TAG=${TAG:-latest}
IMAGE_NAME="meta-analysis-mvp"

echo -e "${YELLOW}🐳 Building Docker image: ${IMAGE_NAME}:${BUILD_TAG}${NC}"

# Build with BuildKit for better performance
DOCKER_BUILDKIT=1 docker build \
    --progress=plain \
    --tag "${IMAGE_NAME}:${BUILD_TAG}" \
    --tag "${IMAGE_NAME}:latest" \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    $([ "$BUILD_CACHE" = "true" ] && echo "--cache-from ${IMAGE_NAME}:latest" || echo "--no-cache") \
    .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Docker image built successfully!${NC}"
    echo ""
    echo "📊 Image Details:"
    docker images "${IMAGE_NAME}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    echo ""
    echo "🚀 To run the container, use:"
    echo "   ./docker-run.sh"
    echo ""
    echo "Or use Docker Compose:"
    echo "   docker-compose up"
else
    echo -e "${RED}❌ Build failed. Please check the error messages above.${NC}"
    exit 1
fi

# Optional: Prune dangling images
echo -e "${YELLOW}🧹 Cleaning up dangling images...${NC}"
docker image prune -f

echo -e "${GREEN}✨ Build complete!${NC}"
