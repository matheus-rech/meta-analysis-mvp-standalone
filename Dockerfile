# Multi-stage build for Meta-Analysis MVP with optimizations
FROM node:18-alpine AS builder

# Install build dependencies
RUN apk add --no-cache python3 make g++

# Set working directory
WORKDIR /app

# Copy package files first for better layer caching
COPY package*.json ./
COPY tsconfig.json ./

# Install ALL dependencies (including dev) for building
RUN npm ci && \
    npm cache clean --force

# Copy source code
COPY src ./src

# Build TypeScript with production optimizations
RUN npm run build

# Production image with R-base
FROM r-base:4.3.2

# Install system dependencies in a single layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    pandoc \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install R packages with parallel installation and specific CRAN mirror
RUN R -e "options(repos = c(CRAN = 'https://cloud.r-project.org/')); \
    install.packages(c('meta', 'metafor', 'jsonlite', 'ggplot2', 'rmarkdown', 'knitr'), \
    Ncpus = parallel::detectCores(), \
    clean = TRUE)"

# Create app directory and set permissions
WORKDIR /app

# Create non-root user early
RUN useradd -m -s /bin/bash metaanalysis && \
    mkdir -p /app/sessions /app/scripts /app/templates && \
    chown -R metaanalysis:metaanalysis /app

# Copy built files from builder with specific ownership
COPY --from=builder --chown=metaanalysis:metaanalysis /app/build ./build
COPY --from=builder --chown=metaanalysis:metaanalysis /app/node_modules ./node_modules
COPY --chown=metaanalysis:metaanalysis package*.json ./

# Copy scripts and templates
COPY --chown=metaanalysis:metaanalysis scripts ./scripts
COPY --chown=metaanalysis:metaanalysis templates ./templates

# Add health check script
RUN echo '#!/bin/bash\nnode -e "process.exit(0)" && Rscript -e "cat(\"R is healthy\\n\")"' > /app/healthcheck.sh && \
    chmod +x /app/healthcheck.sh && \
    chown metaanalysis:metaanalysis /app/healthcheck.sh

# Set environment variables
ENV NODE_ENV=production \
    SESSIONS_DIR=/app/sessions \
    SCRIPTS_DIR=/app/scripts \
    NODE_OPTIONS="--max-old-space-size=2048"

# Switch to non-root user
USER metaanalysis

# Health check - verify both Node.js and R are functional
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /app/healthcheck.sh || exit 1

# Expose port for future HTTP interface
EXPOSE 3000

# Add labels for image metadata
LABEL maintainer="Meta-Analysis MVP Team" \
      version="1.0.0" \
      description="Meta-Analysis MCP Server with R integration"

# Start the MCP server
CMD ["node", "build/index.js"]