#!/bin/bash

# Docker Build Script for production-grade-features branch
# This script builds and tags the Docker image for production deployment

set -e

# Configuration
BRANCH="production-grade-features"
DOCKER_IMAGE="meta-analysis-mvp"
DOCKER_TAG="production"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-docker.io}"
DOCKER_USERNAME="${DOCKER_USERNAME:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Building Docker image for $BRANCH branch${NC}"

# Check current branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
    echo -e "${YELLOW}⚠️  Warning: You're not on the $BRANCH branch${NC}"
    echo "Current branch: $CURRENT_BRANCH"
    read -p "Do you want to continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Build cancelled${NC}"
        exit 1
    fi
fi

# Get git commit hash for tagging
GIT_COMMIT=$(git rev-parse --short HEAD)
GIT_STATUS=$(git status --porcelain)

if [ -n "$GIT_STATUS" ]; then
    echo -e "${YELLOW}⚠️  Warning: You have uncommitted changes${NC}"
    git status --short
fi

# Build timestamp
BUILD_DATE=$(date -u +'%Y%m%d-%H%M%S')

# Construct image tags
if [ -n "$DOCKER_USERNAME" ]; then
    IMAGE_BASE="$DOCKER_REGISTRY/$DOCKER_USERNAME/$DOCKER_IMAGE"
else
    IMAGE_BASE="$DOCKER_IMAGE"
fi

IMAGE_TAGS=(
    "$IMAGE_BASE:$DOCKER_TAG"
    "$IMAGE_BASE:$DOCKER_TAG-$GIT_COMMIT"
    "$IMAGE_BASE:$DOCKER_TAG-$BUILD_DATE"
)

echo -e "${GREEN}📦 Building Docker image...${NC}"
echo "Base image: $IMAGE_BASE"
echo "Tags to be created:"
for tag in "${IMAGE_TAGS[@]}"; do
    echo "  - $tag"
done

# Build the Docker image
docker build \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    --build-arg GIT_COMMIT="$GIT_COMMIT" \
    --build-arg VERSION="$DOCKER_TAG" \
    -t "${IMAGE_TAGS[0]}" \
    .

# Check if build was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Docker image built successfully${NC}"
    
    # Tag with additional tags
    for i in "${!IMAGE_TAGS[@]}"; do
        if [ $i -gt 0 ]; then
            docker tag "${IMAGE_TAGS[0]}" "${IMAGE_TAGS[$i]}"
            echo "Tagged: ${IMAGE_TAGS[$i]}"
        fi
    done
    
    echo ""
    echo -e "${GREEN}🎉 Build complete!${NC}"
    echo ""
    echo "To run the container locally:"
    echo "  docker run -p 3000:3000 ${IMAGE_TAGS[0]}"
    echo ""
    echo "To push to registry:"
    for tag in "${IMAGE_TAGS[@]}"; do
        echo "  docker push $tag"
    done
    echo ""
    echo "To push all tags at once:"
    echo "  ./ci-push-production.sh"
else
    echo -e "${RED}❌ Docker build failed${NC}"
    exit 1
fi
