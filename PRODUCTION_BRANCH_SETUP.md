# Production Grade Features Branch - Environment Setup

This document provides complete setup instructions for the `production-grade-features` branch with CI/CD automation and Cursor Agent support.

## 🚀 Quick Start

Run the automated setup:
```bash
./setup-production-branch.sh
```

This will:
- Configure the production-grade-features branch
- Install dependencies
- Build the project
- Set up GitHub Actions
- Create Docker images
- Configure environment variables

## 📁 Project Structure

### CI/CD Scripts
- `ci-setup-production.sh` - Sets up GitHub Actions workflow
- `ci-build-production.sh` - Builds Docker images for production
- `ci-push-production.sh` - Pushes images to Docker Hub
- `setup-branch-protection.sh` - Configures GitHub branch protection
- `setup-production-branch.sh` - Main setup orchestrator

### Cursor Agent Environment
- `.cursor/Dockerfile` - Agent environment configuration
- `.cursor/environment.json` - Agent settings and extensions

## 🔧 Manual Setup Steps

### 1. Switch to Production Branch
```bash
git checkout -b production-grade-features
# or if it exists
git checkout production-grade-features
```

### 2. Install Dependencies
```bash
npm install
npm run build
```

### 3. Build Docker Image
```bash
./ci-build-production.sh
```

### 4. Configure GitHub Secrets

Go to your GitHub repository:
1. Navigate to Settings → Secrets and variables → Actions
2. Add the following secrets:
   - `DOCKER_USERNAME` - Your Docker Hub username
   - `DOCKER_PASSWORD` - Your Docker Hub password/token

### 5. Push to GitHub
```bash
git add -A
git commit -m "Setup production-grade-features branch with CI/CD"
git push -u origin production-grade-features
```

### 6. Enable Branch Protection (Optional)
```bash
# Requires GitHub CLI (gh) to be installed and authenticated
./setup-branch-protection.sh
```

## 🐳 Docker Commands

### Build Image
```bash
./ci-build-production.sh
```

### Run Container
```bash
docker run -p 3000:3000 meta-analysis-mvp:production
```

### Push to Registry
```bash
./ci-push-production.sh
```

### Docker Compose
```bash
docker-compose up
```

## 🤖 Cursor Agent Configuration

The Cursor Agent environment is configured in `.cursor/`:

### Dockerfile Features
- Ubuntu 22.04 base with non-root user (`ubuntu`)
- R 4.3.2 with metafor, ggplot2, and analysis packages
- Node.js with TypeScript tooling
- Working directory: `/home/ubuntu`
- No code copying (agent clones the repository)

### Environment Settings
- Branch: `production-grade-features`
- Port forwarding: 3000, 8080
- Auto-install and build on creation
- VS Code extensions for R, TypeScript, Docker

## 📋 GitHub Actions Workflow

The CI/CD pipeline (`.github/workflows/production-ci.yml`) includes:

### Triggers
- Push to `production-grade-features` branch
- Pull requests to `production-grade-features`
- Manual workflow dispatch

### Jobs
1. **Test** - Runs on every trigger
   - Installs dependencies
   - Builds TypeScript
   - Runs test suite

2. **Build and Push** - Only on push to production branch
   - Builds Docker image
   - Tags with production, commit SHA, and timestamp
   - Pushes to Docker Hub

3. **Deploy** - After successful build
   - Deploys to production environment
   - (Configure deployment scripts as needed)

## 🔐 Branch Protection Rules

When enabled, the production-grade-features branch will have:
- Required status checks (test, build-and-push)
- Required pull request reviews (1 approval)
- Dismiss stale reviews on new commits
- Require conversation resolution
- Prevent force pushes and deletions

## 📝 Environment Variables

Create a `.env` file with:
```bash
NODE_ENV=production
PORT=3000
BRANCH=production-grade-features
DOCKER_IMAGE=meta-analysis-mvp
DOCKER_TAG=production
DOCKER_USERNAME=your-docker-username
DOCKER_PASSWORD=your-docker-password
```

**Note:** Never commit `.env` files with credentials!

## 🧪 Testing

### Run Tests
```bash
npm test
```

### Test Docker Build
```bash
docker build -t test-build .
docker run --rm test-build npm test
```

### Health Check
```bash
./healthcheck.sh
```

## 🚨 Troubleshooting

### Docker Build Fails
- Ensure Docker daemon is running
- Check available disk space
- Verify Dockerfile syntax

### GitHub Actions Fails
- Check GitHub Secrets are configured
- Verify branch name matches workflow triggers
- Review action logs for specific errors

### Cursor Agent Issues
- Ensure `.cursor/Dockerfile` exists
- Verify USER and WORKDIR are set correctly
- Check that code is not copied in Dockerfile

## 📚 Additional Resources

- [Cursor Agent Documentation](https://cursor.com/environment-json-dockerfile.md)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)

## 🤝 Support

For issues or questions:
1. Check the troubleshooting section
2. Review GitHub Actions logs
3. Open an issue in the repository

---

**Note:** This setup is specifically configured for the `production-grade-features` branch, replacing the previous `meta` branch configuration as per project requirements.
