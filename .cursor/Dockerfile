# ===========================
# Stage 1: R Dependencies
# ===========================
FROM r-base:4.3.2 AS r-deps
# Install required R packages
RUN R -e "install.packages(c('jsonlite', 'metafor', 'ggplot2'), repos='https://cloud.r-project.org/', clean=TRUE)" && \
    rm -rf /tmp/* /var/tmp/* /usr/lib/R/library/*/help /usr/lib/R/library/*/doc

# ===========================
# Stage 2: Final Image
# ===========================
FROM node:18-slim

# Install minimal R runtime and essential tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    r-base-core \
    libcurl4-openssl-dev \
    libxml2 \
    libssl3 \
    git \
    curl \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy R packages from build stage
COPY --from=r-deps /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# Install only essential global Node.js tools
RUN npm install -g \
    typescript@5.7.2 \
    tsx@4.19.2 \
    nodemon@3.1.9 \
    && npm cache clean --force

# Create non-root user
RUN useradd -m -s /bin/bash -u 1000 ubuntu

# Set working directory
WORKDIR /home/ubuntu

# Switch to non-root user
USER ubuntu

# Simple health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node --version && R --version || exit 1

# Environment setup
ENV NODE_ENV=production
ENV PATH="/home/ubuntu/.local/bin:${PATH}"

# Note: Project code will be cloned by the agent
# This provides the minimal environment for meta-analysis tasks