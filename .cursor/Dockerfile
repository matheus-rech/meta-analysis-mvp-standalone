# Dockerfile for Cursor Background Agent
# Following https://cursor.com/environment-json-dockerfile.md guidelines

FROM rocker/r-ver:4.3.2 AS r-builder

# Install R packages
RUN R -e "install.packages(c('metafor', 'jsonlite', 'ggplot2', 'markdown', 'rmarkdown', 'knitr', 'reticulate'), repos='https://cran.rstudio.com/', dependencies=TRUE)"

# Main stage
FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # R runtime dependencies
    r-base \
    r-base-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    # Node.js and development tools
    curl \
    git \
    nodejs \
    npm \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Copy R packages from builder
COPY --from=r-builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# Create non-root user (required for background agents)
RUN useradd -m -s /bin/bash ubuntu && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set working directory to user home (required for background agents)
WORKDIR /home/ubuntu

# Install Node.js dependencies globally
RUN npm install -g typescript tsx nodemon @types/node

# Switch to non-root user
USER ubuntu

# Set environment variables
ENV NODE_ENV=development
ENV R_LIBS_USER=/home/ubuntu/R/library
ENV PATH="/home/ubuntu/.local/bin:${PATH}"

# Create R library directory for user packages
RUN mkdir -p /home/ubuntu/R/library

# Note: Project code will be cloned by the agent - DO NOT COPY CODE
# This follows the Cursor background agent best practices
