# Multi-stage build for Meta-Analysis MVP
FROM node:18-alpine AS builder

# Install build dependencies
RUN apk add --no-cache python3 make g++

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY src ./src

# Build TypeScript
RUN npm run build

# Production image
FROM r-base:4.3.2

# Install Node.js
RUN apt-get update && \
    apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('meta', 'metafor', 'jsonlite', 'ggplot2', 'rmarkdown', 'knitr'), repos='https://cloud.r-project.org/')"

# Install pandoc for report generation
RUN apt-get update && \
    apt-get install -y pandoc && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy built files from builder
COPY --from=builder /app/build ./build
COPY --from=builder /app/node_modules ./node_modules
COPY package*.json ./

# Copy scripts and create directories
COPY scripts ./scripts
RUN mkdir -p sessions

# Set environment
ENV NODE_ENV=production

# Create non-root user
RUN useradd -m -s /bin/bash metaanalysis && \
    chown -R metaanalysis:metaanalysis /app

USER metaanalysis

# Expose port (if needed for future HTTP interface)
EXPOSE 3000

# Start the MCP server
CMD ["node", "build/index.js"]