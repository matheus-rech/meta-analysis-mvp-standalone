# Docker Hub & GitHub Actions Setup Guide

## Prerequisites

1. **Docker Hub Account**: Sign up at [hub.docker.com](https://hub.docker.com)
2. **GitHub Repository**: Your code should be in a GitHub repository

## Step 1: Docker Hub Setup

### 1.1 Create Repository on Docker Hub

1. Log in to [Docker Hub](https://hub.docker.com)
2. Click "Create Repository"
3. Name it: `meta-analysis-mvp`
4. Set visibility (Public or Private)
5. Add description and README

### 1.2 Generate Access Token

1. Go to Account Settings → Security
2. Click "New Access Token"
3. Name: `github-actions` (or similar)
4. Permissions: Read, Write, Delete
5. Copy the token (you'll see it only once!)

## Step 2: GitHub Repository Setup

### 2.1 Add Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:
- `DOCKER_HUB_USERNAME`: Your Docker Hub username
- `DOCKER_HUB_TOKEN`: The access token from step 1.2

### 2.2 Enable GitHub Actions

1. Go to Actions tab in your repository
2. Enable workflows if not already enabled

## Step 3: Trigger Your First Build

### Option A: Push to Main Branch
```bash
git add .
git commit -m "Add Docker workflows"
git push origin main
```

### Option B: Manual Trigger
1. Go to Actions tab
2. Select "Quick Docker Build (Cloud)"
3. Click "Run workflow"
4. Choose options and run

### Option C: Create a Release
```bash
git tag v1.0.0
git push origin v1.0.0
```

## Step 4: Monitor Build

1. Go to Actions tab to see build progress
2. Check Docker Hub for the pushed image
3. Build typically takes 10-15 minutes

## Using the Built Image

Once built and pushed to Docker Hub:

```bash
# Pull the image
docker pull YOUR_USERNAME/meta-analysis-mvp:latest

# Run the container
docker run -it --rm \
  -v $(pwd)/sessions:/app/sessions \
  YOUR_USERNAME/meta-analysis-mvp:latest

# Or use docker-compose
docker-compose pull
docker-compose up
```

## Alternative: Docker Cloud Build

Docker Hub also supports automated builds:

1. Go to your Docker Hub repository
2. Click "Builds" → "Configure Automated Builds"
3. Link your GitHub account
4. Select repository and branch
5. Configure build rules

### Build Rules Example:
- Source: `/^v([0-9.]+)$/`
- Docker Tag: `{sourceref}`
- Source: `main`
- Docker Tag: `latest`

## Troubleshooting

### Build Fails with "tsc not found"
- Ensure TypeScript is in dependencies, not just devDependencies
- Or install all dependencies in builder stage: `npm ci` instead of `npm ci --only=production`

### Build Takes Too Long
- Use GitHub Actions cache
- Consider building only for your target platform initially
- Use Docker Hub's automated builds for multi-arch

### Permission Denied
- Ensure Docker Hub token has write permissions
- Check GitHub secrets are correctly set

### Out of Space
- GitHub Actions provides ~14GB disk space
- Consider using `docker system prune` in workflow
- Use multi-stage builds to reduce image size

## Build Time Optimization

To speed up builds:

1. **Use Registry Cache**:
   ```yaml
   cache-from: type=registry,ref=YOUR_USERNAME/meta-analysis-mvp:buildcache
   cache-to: type=registry,ref=YOUR_USERNAME/meta-analysis-mvp:buildcache,mode=max
   ```

2. **Build Single Architecture First**:
   ```yaml
   platforms: linux/amd64  # Just one platform for testing
   ```

3. **Use GitHub Actions Cache**:
   ```yaml
   cache-from: type=gha
   cache-to: type=gha,mode=max
   ```

## Cost Considerations

- **GitHub Actions**: 2,000 minutes/month free for public repos
- **Docker Hub**: 
  - Free: 1 private repo, unlimited public
  - Pro: $5/month for unlimited private repos
  - Team: $7/user/month with collaboration features

## Next Steps

1. Update `DOCKER_HUB_README.md` with your username
2. Push code to trigger build
3. Test the published image
4. Set up badges in your README:

```markdown
![Docker Build](https://github.com/YOUR_USERNAME/meta-analysis-mvp/actions/workflows/docker-build.yml/badge.svg)
![Docker Pulls](https://img.shields.io/docker/pulls/YOUR_USERNAME/meta-analysis-mvp)
![Docker Image Size](https://img.shields.io/docker/image-size/YOUR_USERNAME/meta-analysis-mvp)
```

## Support

For issues with:
- GitHub Actions: Check Actions tab for logs
- Docker Hub: Check build logs in Docker Hub
- Local builds: Run with `--progress=plain` for detailed output
