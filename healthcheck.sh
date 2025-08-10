#!/usr/bin/env bash
set -euo pipefail

# Minimal container healthcheck
# - Verifies required R packages are present
# - Verifies Node is available
# - Verifies build artifact exists

# Check R packages
Rscript -e "
pkgs <- c('meta', 'metafor', 'jsonlite')
missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly=TRUE)]
if (length(missing) > 0) {
  cat('Missing R packages:', paste(missing, collapse=', '), '\n')
  quit(status=1)
}
" >/dev/null 2>&1

# Check Node
node -e "process.exit(0)" >/dev/null 2>&1

# Check server build exists
test -f /app/build/index.js

echo "ok"

