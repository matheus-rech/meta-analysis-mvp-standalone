# Cursor BugBot Configuration

This file configures BugBot to automatically fix CI issues, address PR feedback, and keep the Meta-Analysis MCP server healthy.

## Goals
- Keep CI green across Node + R + Docker
- Address PR review comments with minimal, targeted edits
- Preserve project architecture and decision rules

## Triggers
- CI failures on PRs or default branch
- New/updated review comments requesting changes
- Security or dependency alerts that break the build

## Repository structure (authoritative)
- `src/` TypeScript MCP server
- `scripts/entry/` R dispatcher (`mcp_tools.R`)
- `scripts/tools/` R tool implementations
- `scripts/adapters/` R statistical adapters (meta/metafor)
- `templates/` Rmd report templates
- `.github/workflows/` CI workflows
- `Dockerfile`, `README.md`, `docs/decision-rules.md`

## Priorities (in order)
1) Fix failing CI (Docker build, Node build, R scripts/tests)
2) Address PR review comments with concrete code edits
3) Small hygiene fixes (paths, typos) if clearly beneficial

## Guardrails
- Do NOT change git config, secrets, or branch protections
- Do NOT commit large binaries; honor `.gitattributes` (png/pdf/docx/rds/xlsx via LFS)
- Prefer minimal diffs; keep existing code style/structure
- No long‑running commands (dev servers, watchers)

## Commands (use these to reproduce/fix)
### Node / TypeScript
- `npm ci`
- `npm run build`
- `node test-mvp.js`

### R scripts (non-interactive smoke)
- `Rscript --version`
- `Rscript scripts/entry/mcp_tools.R health_check "{}" .` (ignore error if unknown tool; existence proves R works)
- `Rscript tests/r/<file>.R` (when present)

### Docker (optional, if runner supports)
- `docker build -t meta-analysis-mvp:local .`

## CI expectations
- Use rocker/r2u base (binary R packages) and Buildx cache
- Avoid TeX/PDF generation in CI; prefer HTML
- Install required R packages in Dockerfile: meta, metafor, jsonlite, ggplot2, rmarkdown, knitr, readxl, base64enc, DT

## Playbooks
### A. MCP routing broken
1. Ensure `src/config.ts` returns `scripts/entry/mcp_tools.R`
2. Verify dispatcher sources `../tools` and `../adapters` with correct relative paths

### B. Excel upload fails
1. Check `readxl` presence (Dockerfile) and base64 decoding in `upload_data.R`
2. Respect optional `sheet_name`; normalize columns; drop empty rows/cols

### C. Forest plot errors
1. Confirm adapter method selection per effect measure (PROP/OR/RR/MD/SMD/MEAN)
2. For PROP, auto‑select sm (PFT/PLOGIT/PRAW) and use GLMM
3. Honor `plot_options` overrides if provided

### D. Effect size ingestion (metagen)
1. Accept TE+seTE or derive from CI for ratio measures
2. Default `method.tau = "REML"`; ensure studlab mapping

### E. CI timeouts/build failures
1. Ensure Dockerfile uses rocker/r2u and lists required R packages
2. Ensure GH Actions uses Buildx cache and linux/amd64 only

## Review comment handling
1. Reproduce locally
2. Implement minimal fix
3. Add/adjust tests where feasible
4. Reply with rationale and link to the commit/lines changed

## Style rules
- TypeScript: explicit types on interfaces/exports; readable control flow
- R: pure helpers; concise roxygen headers on exported functions
- Docs: update `docs/decision-rules.md` and `README.md` for behavior changes

## Done criteria
- CI green (Docker build, Node build, R scripts/tests)
- All review comments addressed or explained
- No large files committed outside LFS rules
