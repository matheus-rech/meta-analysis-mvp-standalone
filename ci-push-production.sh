#!/bin/bash

# Docker Push Script for production-grade-features branch
# This script pushes the built Docker images to the registry

set -e

# Configuration
DOCKER_IMAGE="meta-analysis-mvp"
DOCKER_TAG="production"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-docker.io}"
DOCKER_USERNAME="${DOCKER_USERNAME:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Pushing Docker images for production-grade-features branch${NC}"

# Check if Docker username is set
if [ -z "$DOCKER_USERNAME" ]; then
    echo -e "${YELLOW}⚠️  DOCKER_USERNAME not set${NC}"
    read -p "Enter Docker Hub username: " DOCKER_USERNAME
    if [ -z "$DOCKER_USERNAME" ]; then
        echo -e "${RED}❌ Docker username is required${NC}"
        exit 1
    fi
fi

# Construct image base
IMAGE_BASE="$DOCKER_REGISTRY/$DOCKER_USERNAME/$DOCKER_IMAGE"

# Check if logged in to Docker
echo -e "${BLUE}🔐 Checking Docker login status...${NC}"
if ! docker info 2>/dev/null | grep -q "Username: $DOCKER_USERNAME"; then
    echo "Please log in to Docker Hub:"
    docker login -u "$DOCKER_USERNAME"
fi

# Get list of images to push
echo -e "${BLUE}📋 Finding images to push...${NC}"
IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "^$IMAGE_BASE:$DOCKER_TAG" || true)

if [ -z "$IMAGES" ]; then
    echo -e "${YELLOW}⚠️  No images found matching $IMAGE_BASE:$DOCKER_TAG*${NC}"
    echo "Please run ./ci-build-production.sh first"
    exit 1
fi

echo "Found images to push:"
echo "$IMAGES" | while read -r image; do
    echo "  - $image"
done

# Confirm before pushing
echo ""
read -p "Push these images to Docker Hub? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Push cancelled${NC}"
    exit 0
fi

# Push images
echo ""
echo -e "${GREEN}📤 Pushing images...${NC}"
echo "$IMAGES" | while read -r image; do
    echo -e "${BLUE}Pushing: $image${NC}"
    docker push "$image"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully pushed: $image${NC}"
    else
        echo -e "${RED}❌ Failed to push: $image${NC}"
        exit 1
    fi
done

echo ""
echo -e "${GREEN}🎉 All images pushed successfully!${NC}"
echo ""
echo "Images are now available at:"
echo "$IMAGES" | while read -r image; do
    echo "  https://hub.docker.com/r/$DOCKER_USERNAME/$DOCKER_IMAGE"
    break
done
echo ""
echo "To pull the latest production image:"
echo "  docker pull $IMAGE_BASE:$DOCKER_TAG"
