#!/bin/bash

# GitHub and Docker Hub Automated Setup Script
# This script automates the setup of GitHub secrets and Docker Hub integration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🚀 GitHub & Docker Hub Automated Setup"
echo "======================================"
echo ""

# Function to install GitHub CLI
install_gh_cli() {
    echo -e "${YELLOW}📦 Installing GitHub CLI...${NC}"
    
    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install gh
        else
            echo -e "${YELLOW}Installing Homebrew first...${NC}"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            brew install gh
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt &> /dev/null; then
            # Debian/Ubuntu
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update
            sudo apt install gh
        elif command -v yum &> /dev/null; then
            # RHEL/CentOS/Fedora
            sudo dnf install 'dnf-command(config-manager)'
            sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
            sudo dnf install gh
        else
            echo -e "${RED}❌ Unsupported Linux distribution. Please install gh manually.${NC}"
            echo "Visit: https://github.com/cli/cli#installation"
            exit 1
        fi
    else
        echo -e "${RED}❌ Unsupported OS. Please install gh manually.${NC}"
        echo "Visit: https://github.com/cli/cli#installation"
        exit 1
    fi
}

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}GitHub CLI not found.${NC}"
    read -p "Would you like to install it? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_gh_cli
    else
        echo -e "${RED}❌ GitHub CLI is required. Please install it manually.${NC}"
        echo "Visit: https://github.com/cli/cli#installation"
        exit 1
    fi
fi

# Authenticate with GitHub
echo -e "${BLUE}🔐 Authenticating with GitHub...${NC}"
if ! gh auth status &> /dev/null; then
    echo "Please authenticate with GitHub:"
    gh auth login
else
    echo -e "${GREEN}✅ Already authenticated with GitHub${NC}"
fi

# Get repository information
echo -e "${BLUE}📝 Repository Setup${NC}"
REPO_NAME=$(basename $(pwd))
read -p "Enter your GitHub username/org [$(gh api user --jq .login)]: " GITHUB_USER
GITHUB_USER=${GITHUB_USER:-$(gh api user --jq .login)}

read -p "Repository name [$REPO_NAME]: " REPO_INPUT
REPO_NAME=${REPO_INPUT:-$REPO_NAME}

# Check if repository exists on GitHub
echo -e "${BLUE}🔍 Checking repository...${NC}"
if gh repo view "$GITHUB_USER/$REPO_NAME" &> /dev/null; then
    echo -e "${GREEN}✅ Repository exists on GitHub${NC}"
else
    echo -e "${YELLOW}Repository not found on GitHub.${NC}"
    read -p "Would you like to create it? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Make repository public? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            gh repo create "$GITHUB_USER/$REPO_NAME" --public --source=. --remote=origin --push
        else
            gh repo create "$GITHUB_USER/$REPO_NAME" --private --source=. --remote=origin --push
        fi
    else
        echo -e "${RED}❌ Repository must exist on GitHub to continue.${NC}"
        exit 1
    fi
fi

# Docker Hub Setup
echo ""
echo -e "${BLUE}🐳 Docker Hub Configuration${NC}"
echo "Please have your Docker Hub credentials ready."
echo ""

read -p "Enter your Docker Hub username: " DOCKER_HUB_USERNAME
if [ -z "$DOCKER_HUB_USERNAME" ]; then
    echo -e "${RED}❌ Docker Hub username is required${NC}"
    exit 1
fi

echo -e "${YELLOW}⚠️  You need to create a Docker Hub access token${NC}"
echo "1. Go to: https://hub.docker.com/settings/security"
echo "2. Click 'New Access Token'"
echo "3. Name it: github-actions"
echo "4. Permissions: Read, Write, Delete"
echo "5. Copy the token"
echo ""
read -s -p "Paste your Docker Hub access token: " DOCKER_HUB_TOKEN
echo ""

if [ -z "$DOCKER_HUB_TOKEN" ]; then
    echo -e "${RED}❌ Docker Hub token is required${NC}"
    exit 1
fi

# Add GitHub Secrets
echo ""
echo -e "${BLUE}🔒 Adding GitHub Secrets...${NC}"

# Add Docker Hub username secret
echo -e "${YELLOW}Adding DOCKER_HUB_USERNAME...${NC}"
echo "$DOCKER_HUB_USERNAME" | gh secret set DOCKER_HUB_USERNAME --repo="$GITHUB_USER/$REPO_NAME"

# Add Docker Hub token secret
echo -e "${YELLOW}Adding DOCKER_HUB_TOKEN...${NC}"
echo "$DOCKER_HUB_TOKEN" | gh secret set DOCKER_HUB_TOKEN --repo="$GITHUB_USER/$REPO_NAME"

echo -e "${GREEN}✅ Secrets added successfully!${NC}"

# Update files with actual username
echo ""
echo -e "${BLUE}📝 Updating configuration files...${NC}"

# Update README.md
if [ -f "README.md" ]; then
    sed -i.bak "s/YOUR_USERNAME/$GITHUB_USER/g" README.md
    rm README.md.bak
    echo -e "${GREEN}✅ Updated README.md${NC}"
fi

# Update DOCKER_HUB_README.md
if [ -f "DOCKER_HUB_README.md" ]; then
    sed -i.bak "s/YOUR_USERNAME/$DOCKER_HUB_USERNAME/g" DOCKER_HUB_README.md
    rm DOCKER_HUB_README.md.bak
    echo -e "${GREEN}✅ Updated DOCKER_HUB_README.md${NC}"
fi

# Update docker-compose.yml if needed
if [ -f "docker-compose.yml" ]; then
    sed -i.bak "s/YOUR_USERNAME/$DOCKER_HUB_USERNAME/g" docker-compose.yml
    rm docker-compose.yml.bak
fi

# Commit changes if any
if git diff --quiet; then
    echo -e "${YELLOW}No file changes to commit${NC}"
else
    echo -e "${BLUE}📝 Committing configuration updates...${NC}"
    git add -A
    git commit -m "chore: update configuration with actual usernames"
fi

# Push to GitHub
echo ""
echo -e "${BLUE}📤 Pushing to GitHub...${NC}"
CURRENT_BRANCH=$(git branch --show-current)
git push origin "$CURRENT_BRANCH"

# Enable GitHub Actions if not already enabled
echo ""
echo -e "${BLUE}⚙️  Enabling GitHub Actions...${NC}"
gh api -X PUT "repos/$GITHUB_USER/$REPO_NAME/actions/permissions" \
  -f enabled=true \
  -f allowed_actions=all &> /dev/null || true

# Trigger the first build
echo ""
echo -e "${BLUE}🚀 Triggering first build...${NC}"
read -p "Would you like to trigger the first Docker build now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Triggering workflow...${NC}"
    gh workflow run docker-quick-build.yml \
      --repo="$GITHUB_USER/$REPO_NAME" \
      -f platform="linux/amd64" \
      -f tag="latest"
    
    echo -e "${GREEN}✅ Build triggered!${NC}"
    echo ""
    echo -e "${BLUE}📊 Monitor your build at:${NC}"
    echo "https://github.com/$GITHUB_USER/$REPO_NAME/actions"
fi

# Create Docker Hub repository
echo ""
echo -e "${BLUE}🐳 Docker Hub Repository Setup${NC}"
echo -e "${YELLOW}Please create your Docker Hub repository:${NC}"
echo "1. Go to: https://hub.docker.com/repository/create"
echo "2. Name: meta-analysis-mvp"
echo "3. Description: Meta-Analysis MVP - MCP Server with R integration"
echo "4. Visibility: Public (recommended) or Private"
echo ""

# Summary
echo ""
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo "  • GitHub Repository: https://github.com/$GITHUB_USER/$REPO_NAME"
echo "  • GitHub Actions: https://github.com/$GITHUB_USER/$REPO_NAME/actions"
echo "  • Docker Hub: https://hub.docker.com/r/$DOCKER_HUB_USERNAME/meta-analysis-mvp"
echo ""
echo -e "${BLUE}🚀 Next Steps:${NC}"
echo "1. Create Docker Hub repository (if not done)"
echo "2. Monitor the build in GitHub Actions"
echo "3. Once built, pull your image:"
echo "   docker pull $DOCKER_HUB_USERNAME/meta-analysis-mvp:latest"
echo ""
echo -e "${GREEN}✨ Your CI/CD pipeline is now active!${NC}"

# Optional: Open browser
read -p "Would you like to open GitHub Actions in your browser? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    gh repo view --web "$GITHUB_USER/$REPO_NAME"
fi
