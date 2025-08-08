# Project review guidelines (Meta-Analysis MCP)

This file guides Cursor BugBot when reviewing or proposing fixes.

## Security focus areas
- Validate MCP tool inputs (schemas in `src/index.ts`); reject unknown tools
- Enforce argument validation in `src/r-executor.ts` (no null bytes, path traversal, size/time limits)
- Cap JSON output size (10MB) and R process timeouts (45s)
- Avoid committing large binaries; rely on Git LFS per `.gitattributes`

## Architecture patterns
- MCP server dispatches to R via `scripts/entry/mcp_tools.R`
- R code split by responsibility: `entry/` dispatcher, `tools/` implementations, `adapters/` for `meta`/`metafor`
- File-based sessions under `sessions/<uuid>/` with `data/`, `processing/`, `results/`
- Docker: rocker/r2u base + GH Actions Buildx cache; no TeX in CI

## Common issues
- Wrong R entry path (ensure `src/config.ts` -> `scripts/entry/mcp_tools.R`)
- Excel uploads failing (ensure `readxl`, base64 decoding, sheet selection)
- Forest plot errors due to method/measure mismatch (confirm adapter choices for `PROP/OR/RR/MD/SMD/MEAN`)
- Slow/failed Docker builds (ensure rocker/r2u and apt-installed R pkgs)

## Commands (use to reproduce)
- Node: `npm ci && npm run build && node test-mvp.js`
- R smoke: `Rscript --version` and `Rscript scripts/entry/mcp_tools.R health_check "{}" .`
- Docker: `docker build -t meta-analysis-mvp:local .`

## CI expectations
- Workflows under `.github/workflows/` use Buildx cache and linux/amd64 only
- Required R packages installed via apt: meta, metafor, jsonlite, ggplot2, rmarkdown, knitr, readxl, base64enc, DT

## Style
- TypeScript: explicit types on public APIs; readable control flow
- R: pure helpers; concise roxygen-style headers for exported functions
- Docs: update `docs/decision-rules.md` and `README.md` on behavior changes

## Decision rules
See `docs/decision-rules.md` for: accepted schemas, method selection, plot defaults, subgroup handling, and estimation rules (estmeansd).
