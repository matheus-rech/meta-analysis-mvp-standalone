#!/bin/bash

# Main Setup Script for production-grade-features branch
# This script initializes the complete environment for the production branch

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Meta-Analysis MVP - Production Grade Features Setup${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Function to check command availability
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✅ $1 is installed${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 is not installed${NC}"
        return 1
    fi
}

# Step 1: Check prerequisites
echo -e "${BLUE}Step 1: Checking prerequisites...${NC}"
MISSING_DEPS=0

check_command git || MISSING_DEPS=1
check_command docker || MISSING_DEPS=1
check_command node || MISSING_DEPS=1
check_command npm || MISSING_DEPS=1

if [ $MISSING_DEPS -eq 1 ]; then
    echo -e "${RED}Please install missing dependencies before continuing${NC}"
    exit 1
fi

# Step 2: Setup Git branch
echo ""
echo -e "${BLUE}Step 2: Setting up production-grade-features branch...${NC}"

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "none")
if [ "$CURRENT_BRANCH" != "production-grade-features" ]; then
    echo "Current branch: $CURRENT_BRANCH"
    
    # Check if branch exists locally
    if git show-ref --verify --quiet refs/heads/production-grade-features; then
        echo "Switching to existing production-grade-features branch..."
        git checkout production-grade-features
    else
        echo "Creating new production-grade-features branch..."
        git checkout -b production-grade-features
    fi
    echo -e "${GREEN}✅ Now on production-grade-features branch${NC}"
else
    echo -e "${GREEN}✅ Already on production-grade-features branch${NC}"
fi

# Step 3: Install Node dependencies
echo ""
echo -e "${BLUE}Step 3: Installing Node.js dependencies...${NC}"
npm install
echo -e "${GREEN}✅ Dependencies installed${NC}"

# Step 4: Build TypeScript
echo ""
echo -e "${BLUE}Step 4: Building TypeScript...${NC}"
npm run build
echo -e "${GREEN}✅ TypeScript build complete${NC}"

# Step 5: Setup GitHub Actions
echo ""
echo -e "${BLUE}Step 5: Setting up GitHub Actions...${NC}"
if [ -f "./ci-setup-production.sh" ]; then
    ./ci-setup-production.sh
else
    echo -e "${YELLOW}⚠️  ci-setup-production.sh not found${NC}"
fi

# Step 6: Build Docker image
echo ""
echo -e "${BLUE}Step 6: Building Docker image for production...${NC}"
read -p "Do you want to build the Docker image now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "./ci-build-production.sh" ]; then
        ./ci-build-production.sh
    else
        docker build -t meta-analysis-mvp:production .
        echo -e "${GREEN}✅ Docker image built${NC}"
    fi
else
    echo "Skipping Docker build"
fi

# Step 7: Setup environment variables
echo ""
echo -e "${BLUE}Step 7: Setting up environment variables...${NC}"
if [ ! -f .env ]; then
    cat > .env << 'EOF'
# Environment variables for production-grade-features branch
NODE_ENV=production
PORT=3000
BRANCH=production-grade-features
DOCKER_IMAGE=meta-analysis-mvp
DOCKER_TAG=production

# Add your Docker Hub credentials here (DO NOT COMMIT)
# DOCKER_USERNAME=your-username
# DOCKER_PASSWORD=your-password
EOF
    echo -e "${GREEN}✅ Created .env file (please add your Docker Hub credentials)${NC}"
else
    echo -e "${YELLOW}⚠️  .env file already exists${NC}"
fi

# Step 8: Display next steps
echo ""
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Setup Complete! 🎉${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. ${BLUE}Add Docker Hub credentials to .env file:${NC}"
echo "   Edit .env and add DOCKER_USERNAME and DOCKER_PASSWORD"
echo ""
echo "2. ${BLUE}Commit and push changes:${NC}"
echo "   git add -A"
echo "   git commit -m 'Setup production-grade-features branch with CI/CD'"
echo "   git push -u origin production-grade-features"
echo ""
echo "3. ${BLUE}Configure GitHub repository secrets:${NC}"
echo "   Go to: Settings → Secrets and variables → Actions"
echo "   Add: DOCKER_USERNAME and DOCKER_PASSWORD"
echo ""
echo "4. ${BLUE}Test the setup:${NC}"
echo "   npm test                    # Run tests"
echo "   docker-compose up           # Run with Docker Compose"
echo "   ./ci-build-production.sh    # Build Docker image"
echo "   ./ci-push-production.sh     # Push to Docker Hub"
echo ""
echo "5. ${BLUE}Set up branch protection (optional):${NC}"
echo "   ./setup-branch-protection.sh"
echo ""
echo -e "${GREEN}For Cursor Agent:${NC}"
echo "The environment is configured in .cursor/Dockerfile and .cursor/environment.json"
echo "The agent will work with the production-grade-features branch automatically."
echo ""
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
