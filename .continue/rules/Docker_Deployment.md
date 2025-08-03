# Docker Deployment Guide
"[\n { \"type\": \"insertAfter\", \"line\": 6, \"text\": \"\\nThis Meta-Analysis MVP uses Docker to package both the Node.js MCP server and R statistical components together in a single container. This ensures all dependencies are properly installed and the components can work together seamlessly.\\n\" },\n { \"type\": \"insertAfter\", \"line\": 28, \"text\": \"\\n## Docker Image Architecture\\n\\n### Container Components\\n\\nThe Docker image contains:\\n\\n1. **Node.js Environment**: For running the MCP server\\n2. **R Environment**: For statistical processing\\n3. **Required R Packages**: `meta`, `metafor`, `jsonlite`, `ggplot2`, etc.\\n4. **Project Code**: TypeScript compiled to JavaScript and R scripts\\n\\n### How Components Work Together\\n\\nInside the container:\\n\\n1. The TypeScript MCP server runs as the main process\\n2. When a tool is invoked, the Node.js server executes the appropriate R script using the `r-executor.ts` module\\n3. The R script processes the statistical data and returns results as JSON\\n4. The MCP server formats and returns the response to the client\\n\\n### Dockerfile Structure\\n\\n```dockerfile\\n# Base image with Node.js\\nFROM node:18-slim\\n\\n# Install R and required dependencies\\nRUN apt-get update && apt-get install -y \\\\\\n r-base \\\\\\n r-base-dev \\\\\\n libcurl4-openssl-dev \\\\\\n libxml2-dev \\\\\\n libssl-dev \\\\\\n && rm -rf /var/lib/apt/lists/*\\n\\n# Install required R packages\\nRUN Rscript -e \\\"install.packages(c('meta', 'metafor', 'jsonlite', 'ggplot2', 'rmarkdown', 'knitr'), repos='https://cloud.r-project.org/')\\\"\\n\\n# Set working directory\\nWORKDIR /app\\n\\n# Copy package files\\nCOPY package*.json ./\\n\\n# Install Node.js dependencies\\nRUN npm install\\n\\n# Copy application code\\nCOPY . .\\n\\n# Build TypeScript\\nRUN npm run build\\n\\n# Start the MCP server\\nCMD [\\\"node\\\", \\\"build/index.js\\\"]\\n```\\n\\nThis Dockerfile: \\n- Starts with Node.js\\n- Installs R and necessary system dependencies\\n- Installs required R packages\\n- Sets up the Node.js environment\\n- Builds the TypeScript code\\n- Runs the MCP server which will call R scripts as needed\\n\" },\n { \"type\": \"insertAfter\", \"line\": 137, \"text\": \"\\n## Verifying R and MCP Integration\\n\\nTo verify that both Node.js MCP server and R are working together correctly:\\n\\n```bash\\n# Run the container with the health check tool\\ndocker run -it --rm meta-analysis-mvp node -e \\\"const { spawn } = require('child_process'); const proc = spawn('node', ['build/index.js']); proc.stdout.on('data', data => { console.log(data.toString()); }); proc.stdin.write(JSON.stringify({jsonrpc: '2.0', id: 1, method: 'tools/call', params: {name: 'health_check', arguments: {detailed: true}}}) + '\\\\n');\\\" \\n```\\n\\nThe health check response should confirm both Node.js and R are working:\\n\\n```json\\n{\\n \\\"status\\\": \\\"success\\\",\\n \\\"message\\\": \\\"Meta-analysis MVP server is healthy\\\",\\n \\\"version\\\": \\\"1.0.0\\\",\\n \\\"r_available\\\": true,\\n \\\"r_packages\\\": {\\n \\\"meta\\\": true,\\n \\\"metafor\\\": true,\\n \\\"jsonlite\\\": true\\n }\\n}\\n```\\n\\n## Running the Demo Workflow in Docker\\n\\nTo execute the complete demo workflow in Docker:\\n\\n```bash\\n# Run the container with the demo workflow\\ndocker run -it --rm meta-analysis-mvp node demo-workflow.js\\n```\\n\\nThis will demonstrate all components working together through the full analysis pipeline:\\n\\n1. Node.js server initializes\\n2. MCP tools are registered\\n3. R scripts are called for various analyses\\n4. Results are processed and returned\\n\\nYou should see output showing each step of the meta-analysis process completing successfully.\\n\" },\n { \"type\": \"insertAfter\", \"line\": 254, \"text\": \"\\n## Multi-container Setup (Advanced)\\n\\nFor advanced deployments, you might separate the Node.js and R components:\\n\\n```yaml\\nversion: '3'\\nservices:\\n # MCP Server container\\n mcp-server:\\n build:\\n context: .\\n dockerfile: Dockerfile.node\\n volumes:\\n - ./sessions:/app/sessions\\n - ./scripts:/app/scripts\\n ports:\\n - \\\"3000:3000\\\"\\n environment:\\n - R_SERVICE_HOST=r-service\\n - R_SERVICE_PORT=6311\\n \\n # R service container\\n r-service:\\n build:\\n context: .\\n dockerfile: Dockerfile.r\\n volumes:\\n - ./sessions:/app/sessions\\n - ./scripts:/app/scripts\\n```\\n\\nThis approach is more complex but allows for separate scaling of Node.js and R services.\\n\" }\n]"
## Overview

This guide explains how to build, run, and deploy the Meta-Analysis MVP using Docker. Docker provides a consistent environment with all dependencies pre-installed, making it easier to run the application across different platforms.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed on your system
- Basic familiarity with Docker commands

## Building the Docker Image

### Basic Build

Build the Docker image using the included Dockerfile:

```bash
# Navigate to the project root
cd meta-analysis-mvp

# Build the image
docker build -t meta-analysis-mvp .
```

The `-t` flag tags the image with a name for easier reference.

### Build with Version Tag

For production deployments, include a version tag:

```bash
docker build -t meta-analysis-mvp:1.0.0 .
```

### Build Arguments

The Dockerfile supports these build arguments:

- `NODE_ENV`: Set to `production` for optimized builds (default: `development`)
- `R_VERSION`: Specify R version (default: `4.2.0`)

Example with build arguments:

```bash
docker build \
  --build-arg NODE_ENV=production \
  --build-arg R_VERSION=4.3.0 \
  -t meta-analysis-mvp:prod .
```

## Running the Docker Container

### Basic Run

Run the container with default settings:

```bash
docker run -it --rm meta-analysis-mvp
```

- `-it` provides an interactive terminal
- `--rm` removes the container when it exits

### Port Mapping

If you need to access the server from outside the container (e.g., for the MCP Inspector):

```bash
docker run -it --rm -p 3000:3000 meta-analysis-mvp
```

### Persisting Session Data

To persist session data between container runs, mount a volume:

```bash
docker run -it --rm \
  -v "$(pwd)/sessions:/app/sessions" \
  meta-analysis-mvp
```

### Environment Variables

Set environment variables using the `-e` flag:

```bash
docker run -it --rm \
  -e NODE_ENV=production \
  -e SESSIONS_DIR=/data/sessions \
  meta-analysis-mvp
```

### Using the MCP Inspector

Run with the MCP Inspector for interactive testing:

```bash
docker run -it --rm meta-analysis-mvp npm run inspector
```

## Development with Docker

### Running in Development Mode

For development with auto-reload:

```bash
docker run -it --rm \
  -v "$(pwd)/src:/app/src" \
  -v "$(pwd)/scripts:/app/scripts" \
  meta-analysis-mvp npm run dev
```

### Accessing Container Shell

To debug or explore the container:

```bash
docker run -it --rm meta-analysis-mvp /bin/bash
```

### Running Tests

Run tests inside the container:

```bash
docker run -it --rm meta-analysis-mvp node test-mvp.js
```

## Docker Compose (Optional)

For more complex setups, create a `docker-compose.yml` file:

```yaml
version: '3'
services:
  meta-analysis-mvp:
    build:
      context: .
      args:
        - NODE_ENV=production
    volumes:
      - ./sessions:/app/sessions
    environment:
      - NODE_ENV=production
    ports:
      - "3000:3000"
```

Run with Docker Compose:

```bash
docker-compose up
```

## Production Deployment

### Best Practices

1. **Use specific version tags** for production images
2. **Set NODE_ENV to production** for optimized performance
3. **Mount volume for session data** to persist analysis sessions
4. **Consider a reverse proxy** (like Nginx) for production deployments

### Example Production Setup

```bash
# Build production image
docker build \
  --build-arg NODE_ENV=production \
  -t meta-analysis-mvp:1.0.0-prod .

# Run with production settings
docker run -d \
  --name meta-analysis-prod \
  -e NODE_ENV=production \
  -v meta_analysis_sessions:/app/sessions \
  -p 127.0.0.1:3000:3000 \
  meta-analysis-mvp:1.0.0-prod
```

The `-d` flag runs the container in detached mode (background).

### Container Monitoring

Monitor the running container:

```bash
# View logs
docker logs meta-analysis-prod

# Follow logs live
docker logs -f meta-analysis-prod

# Check container status
docker ps
```

### Container Lifecycle Management

```bash
# Stop the container
docker stop meta-analysis-prod

# Start existing container
docker start meta-analysis-prod

# Remove container
docker rm meta-analysis-prod
```

## Troubleshooting

### Common Issues

1. **R Package Installation Failures**
   - Check if R packages are being installed correctly during build
   - Modify the Dockerfile to add specific package versions if needed

2. **Permission Issues with Mounted Volumes**
   - Ensure the host directory has appropriate permissions
   - Add `--user $(id -u):$(id -g)` to the docker run command

3. **Container Exits Immediately**
   - Check logs: `docker logs <container_id>`
   - Ensure the CMD in Dockerfile is correct

### Debugging Container Issues

Connect to a running container for debugging:

```bash
# Get container ID
docker ps

# Connect to running container
docker exec -it <container_id> /bin/bash

# Check R installation
docker exec <container_id> Rscript -e "installed.packages()"
```

## Docker Image Optimization

### Minimize Image Size

- Use multi-stage builds for smaller images
- Remove unnecessary dependencies
- Clear package caches in the same RUN statement

### Security Best Practices

- Use non-root user in the container
- Pin all dependency versions
- Scan the image for vulnerabilities with tools like Trivy or Docker Scan

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [R in Docker](https://www.rocker-project.org/)