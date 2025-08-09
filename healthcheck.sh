#!/usr/bin/env bash
set -euo pipefail

# Minimal container healthcheck
# - Verifies required R packages are present
# - Verifies Node is available
# - Verifies build artifact exists

# Check R packages
Rscript -e "if(!requireNamespace('meta', quietly=TRUE) || !requireNamespace('metafor', quietly=TRUE) || !requireNamespace('jsonlite', quietly=TRUE)) quit(status=1)" >/dev/null 2>&1

# Check Node
node -e "process.exit(0)" >/dev/null 2>&1

# Check server build exists
test -f /app/build/index.js

echo "ok"

