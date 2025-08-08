#!/bin/bash

# Quick GitHub CLI Setup for Docker Hub Integration
# For users who already have gh CLI installed

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🚀 Quick GitHub & Docker Hub Setup (using gh CLI)"
echo "================================================"
echo ""

# Check gh CLI
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI not found. Please run ./setup-github-docker.sh instead"
    exit 1
fi

# Auth check
if ! gh auth status &> /dev/null; then
    echo "Authenticating with GitHub..."
    gh auth login
fi

# Get repo info
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")

if [ -z "$REPO" ]; then
    echo -e "${YELLOW}No GitHub remote found. Setting up...${NC}"
    read -p "GitHub username: " GITHUB_USER
    read -p "Repository name [meta-analysis-mvp]: " REPO_NAME
    REPO_NAME=${REPO_NAME:-meta-analysis-mvp}
    
    echo "Creating repository..."
    gh repo create "$GITHUB_USER/$REPO_NAME" --public --source=. --remote=origin
    REPO="$GITHUB_USER/$REPO_NAME"
fi

echo -e "${GREEN}✅ Using repository: $REPO${NC}"

# Docker Hub credentials
echo ""
echo -e "${BLUE}🐳 Docker Hub Setup${NC}"
read -p "Docker Hub username: " DOCKER_USER
read -s -p "Docker Hub token (hidden): " DOCKER_TOKEN
echo ""

# Set secrets
echo ""
echo "Setting GitHub secrets..."
echo "$DOCKER_USER" | gh secret set DOCKER_HUB_USERNAME
echo "$DOCKER_TOKEN" | gh secret set DOCKER_HUB_TOKEN

echo -e "${GREEN}✅ Secrets configured!${NC}"

# Update files
echo "Updating configuration files..."
GITHUB_USER=$(echo $REPO | cut -d'/' -f1)
sed -i '' "s/YOUR_USERNAME/$GITHUB_USER/g" README.md 2>/dev/null || true
sed -i '' "s/YOUR_USERNAME/$DOCKER_USER/g" DOCKER_HUB_README.md 2>/dev/null || true

# Commit and push
if ! git diff --quiet; then
    git add -A
    git commit -m "chore: update usernames in documentation"
fi

git push origin $(git branch --show-current)

# Trigger build
echo ""
read -p "Trigger Docker build now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    gh workflow run docker-quick-build.yml -f platform="linux/amd64" -f tag="latest"
    echo -e "${GREEN}✅ Build triggered!${NC}"
    echo "Monitor at: https://github.com/$REPO/actions"
fi

echo ""
echo -e "${GREEN}✨ Setup complete!${NC}"
echo "• GitHub: https://github.com/$REPO"
echo "• Docker: hub.docker.com/r/$DOCKER_USER/meta-analysis-mvp"
