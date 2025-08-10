#!/bin/bash

# Script to set up branch protection for production-grade-features
# Run this after pushing to GitHub

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BRANCH="production-grade-features"

echo -e "${BLUE}🔐 Setting up branch protection for $BRANCH...${NC}"

# Extract repository information from git remote
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [ -z "$REMOTE_URL" ]; then
    echo -e "${RED}❌ No git remote found${NC}"
    exit 1
fi

# Parse owner and repo from URL (works with both HTTPS and SSH)
if [[ "$REMOTE_URL" =~ github.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
    REPO_OWNER="${BASH_REMATCH[1]}"
    REPO_NAME="${BASH_REMATCH[2]}"
    REPO_NAME="${REPO_NAME%.git}"  # Remove .git suffix if present
else
    echo -e "${RED}❌ Could not parse GitHub repository from remote URL${NC}"
    echo "Remote URL: $REMOTE_URL"
    exit 1
fi

echo "Repository: $REPO_OWNER/$REPO_NAME"
echo "Branch: $BRANCH"
echo ""

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI (gh) is not installed${NC}"
    echo ""
    echo "To install GitHub CLI:"
    echo "  macOS:  brew install gh"
    echo "  Linux:  See https://github.com/cli/cli#installation"
    echo ""
    echo "After installation, authenticate with: gh auth login"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not authenticated with GitHub CLI${NC}"
    echo "Please run: gh auth login"
    exit 1
fi

echo -e "${BLUE}Configuring branch protection rules...${NC}"

# Create/update branch protection rules
gh api \
    --method PUT \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "repos/$REPO_OWNER/$REPO_NAME/branches/$BRANCH/protection" \
    -f required_status_checks='{"strict":true,"contexts":["test","build-and-push"]}' \
    -F enforce_admins=false \
    -f required_pull_request_reviews='{"dismiss_stale_reviews":true,"require_code_owner_reviews":false,"required_approving_review_count":1,"require_last_push_approval":false}' \
    -F allow_force_pushes=false \
    -F allow_deletions=false \
    -F required_conversation_resolution=true \
    -F lock_branch=false \
    -F allow_fork_syncing=false 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Branch protection rules applied successfully!${NC}"
    echo ""
    echo "Protection rules enabled:"
    echo "  • Require status checks to pass (test, build-and-push)"
    echo "  • Require pull request reviews (1 approval)"
    echo "  • Dismiss stale reviews on new commits"
    echo "  • Require conversation resolution"
    echo "  • Prevent force pushes and deletions"
else
    echo -e "${YELLOW}⚠️  Could not apply all branch protection rules${NC}"
    echo "You may need to configure them manually in GitHub settings"
fi

echo ""
echo -e "${BLUE}To view protection rules:${NC}"
echo "  https://github.com/$REPO_OWNER/$REPO_NAME/settings/branches"
