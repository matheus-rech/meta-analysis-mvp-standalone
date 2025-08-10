#!/bin/bash

# CI/CD Setup Script for production-grade-features branch
# This script sets up GitHub Actions for automated Docker builds and deployment

set -e

echo "🚀 Setting up CI/CD for production-grade-features branch..."

# Check if we're in a git repository
if [ ! -d .git ]; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Create GitHub Actions directory
mkdir -p .github/workflows

# Create the main CI/CD workflow
cat > .github/workflows/production-ci.yml << 'EOF'
name: Production Grade Features CI/CD

on:
  push:
    branches: [ production-grade-features ]
  pull_request:
    branches: [ production-grade-features ]
  workflow_dispatch:

env:
  DOCKER_IMAGE: meta-analysis-mvp
  DOCKER_TAG: production

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run TypeScript build
      run: npm run build
    
    - name: Run tests
      run: npm test

  build-and-push:
    needs: test
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/production-grade-features'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Log in to Docker Hub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
    
    - name: Build and push Docker image
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: |
          ${{ secrets.DOCKER_USERNAME }}/${{ env.DOCKER_IMAGE }}:${{ env.DOCKER_TAG }}
          ${{ secrets.DOCKER_USERNAME }}/${{ env.DOCKER_IMAGE }}:${{ github.sha }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/production-grade-features'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to production
      run: |
        echo "🚀 Deployment to production environment"
        echo "Docker image: ${{ secrets.DOCKER_USERNAME }}/${{ env.DOCKER_IMAGE }}:${{ github.sha }}"
        # Add your deployment scripts here
EOF

echo "✅ GitHub Actions workflow created"

# Create branch protection script
cat > setup-branch-protection.sh << 'EOF'
#!/bin/bash

# Script to set up branch protection for production-grade-features
# Run this after pushing to GitHub

REPO_OWNER=$(git remote get-url origin | sed -n 's/.*github.com[:/]\([^/]*\).*/\1/p')
REPO_NAME=$(basename `git rev-parse --show-toplevel`)
BRANCH="production-grade-features"

echo "Setting up branch protection for $BRANCH..."
echo "Repository: $REPO_OWNER/$REPO_NAME"

# This requires GitHub CLI (gh) to be installed and authenticated
if command -v gh &> /dev/null; then
    gh api repos/$REPO_OWNER/$REPO_NAME/branches/$BRANCH/protection \
        --method PUT \
        --field required_status_checks='{"strict":true,"contexts":["test"]}' \
        --field enforce_admins=false \
        --field required_pull_request_reviews='{"required_approving_review_count":1}' \
        --field restrictions=null
    
    echo "✅ Branch protection rules applied"
else
    echo "⚠️  GitHub CLI not found. Please install 'gh' to set up branch protection"
    echo "   Visit: https://cli.github.com/"
fi
EOF

chmod +x setup-branch-protection.sh

echo "✅ CI/CD setup script created successfully!"
echo ""
echo "Next steps:"
echo "1. Ensure you're on the production-grade-features branch:"
echo "   git checkout -b production-grade-features || git checkout production-grade-features"
echo ""
echo "2. Add the GitHub Actions workflow to git:"
echo "   git add .github/workflows/production-ci.yml"
echo "   git commit -m 'Add CI/CD pipeline for production-grade-features'"
echo ""
echo "3. Push to GitHub:"
echo "   git push -u origin production-grade-features"
echo ""
echo "4. Set up GitHub secrets in your repository settings:"
echo "   - DOCKER_USERNAME"
echo "   - DOCKER_PASSWORD"
echo ""
echo "5. (Optional) Run branch protection setup:"
echo "   ./setup-branch-protection.sh"
