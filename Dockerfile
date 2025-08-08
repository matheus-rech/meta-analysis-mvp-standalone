# Multi-stage build for Meta-Analysis MVP (fast, cached)
# 1) Build TypeScript with Node
FROM node:18-bullseye AS builder

WORKDIR /app

# Install Node dependencies
COPY package*.json tsconfig.json ./
RUN npm ci

# Copy source and build
COPY src ./src
RUN npm run build

# 2) Final image with R (binary packages) + Node
FROM rocker/r2u:4.3.2

# Install Node.js 18 via NodeSource (ensures >=18)
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates gnupg && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install R packages via apt (binary, fast) and pandoc for R Markdown
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      r-cran-meta \
      r-cran-metafor \
      r-cran-jsonlite \
      r-cran-ggplot2 \
      r-cran-rmarkdown \
      r-cran-knitr \
      r-cran-readxl \
      r-cran-base64enc \
      r-cran-dt \
      pandoc && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy build artifacts and runtime deps
COPY --from=builder /app/build ./build
COPY --from=builder /app/node_modules ./node_modules
COPY package*.json ./

# Copy R scripts and templates
COPY scripts ./scripts
COPY templates ./templates

# Prepare sessions directory
RUN mkdir -p sessions && \
    useradd -m -s /bin/bash metaanalysis && \
    chown -R metaanalysis:metaanalysis /app

ENV NODE_ENV=production
USER metaanalysis

# Expose port (placeholder; MCP uses stdio)
EXPOSE 3000

CMD ["node", "build/index.js"]
