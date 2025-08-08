#!/bin/bash

# GitHub and Docker Hub Automated Setup Script for publication-grade-features branch
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🚀 GitHub & Docker Hub Setup for publication-grade-features"
echo "=========================================================="

# Install gh CLI if needed (macOS)
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}Installing GitHub CLI...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew &> /dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install gh
    fi
fi

# Auth with GitHub
if ! gh auth status &> /dev/null; then
    gh auth login
fi

# Get repo info
read -p "GitHub username: " GITHUB_USER
REPO_NAME="meta-analysis-mvp-standalone"

# Create/connect repository
if ! gh repo view "$GITHUB_USER/$REPO_NAME" &> /dev/null; then
    echo "Creating repository..."
    gh repo create "$GITHUB_USER/$REPO_NAME" --public --source=. --remote=origin
fi

# Docker Hub setup
echo -e "${BLUE}🐳 Docker Hub Setup${NC}"
read -p "Docker Hub username: " DOCKER_USER
read -s -p "Docker Hub token: " DOCKER_TOKEN
echo ""

# Set GitHub secrets
echo "Setting secrets..."
echo "$DOCKER_USER" | gh secret set DOCKER_HUB_USERNAME
echo "$DOCKER_TOKEN" | gh secret set DOCKER_HUB_TOKEN

echo -e "${GREEN}✅ Secrets configured!${NC}"

# Update files
sed -i '' "s/YOUR_USERNAME/$GITHUB_USER/g" README.md 2>/dev/null || sed -i "s/YOUR_USERNAME/$GITHUB_USER/g" README.md

# Commit and push
git add -A
git commit -m "chore: configure CI/CD for publication-grade-features branch" || true
git push origin publication-grade-features

# Trigger build
echo -e "${BLUE}🚀 Triggering Docker build...${NC}"
gh workflow run docker-build.yml

echo -e "${GREEN}✨ Setup complete!${NC}"
echo "Monitor build: https://github.com/$GITHUB_USER/$REPO_NAME/actions"
