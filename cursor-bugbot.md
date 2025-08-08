# Cursor BugBot Configuration

## Purpose
Keep the meta-analysis MCP server healthy by automatically fixing failing checks, addressing PR review comments, and maintaining build reliability across Node + R + Docker.

## Scope of work (prioritized)
1. Fix failing CI (Docker build, Node build, R scripts) and broken tests
2. Respond to PR review comments with concrete code edits
3. Maintain repository hygiene (paths, scripts, docs) without altering project intent

## High‑priority paths
- src/** (TypeScript MCP server)
- scripts/** (R tools, adapters, entry)
- templates/** (Rmd report templates)
- Dockerfile, .github/workflows/**
- README.md, docs/**

## Low‑priority / avoid
- sessions/** (generated)
- test-output/**, results artifacts
- Large binaries (keep out of git; rely on Git LFS patterns)

## Guardrails
- Do not change git config, secrets, or branch protections
- Do not commit large binaries; honor .gitattributes (png/pdf/docx/rds/xlsx under LFS)
- Prefer minimal, targeted edits; keep code style and structure
- No long‑running commands (watchers/servers)

## Build and test commands
- Node/TypeScript
  - npm ci
  - npm run build
  - node test-mvp.js
- R scripts (non-interactive)
  - Rscript --version
  - Rscript scripts/entry/mcp_tools.R health_check "{}" .  (expect JSON error or success)
  - Rscript tests/r/<file>.R  (when present)
- Docker (local validation only; optional if runner supports Docker)
  - docker build -t meta-analysis-mvp:local .

## Tactics / decision rules
- If MCP tool routing fails: ensure src/config.ts points to scripts/entry/mcp_tools.R; verify source paths inside dispatcher
- If uploads fail for Excel: check readxl, base64 handling, and sheet selection logic
- If R package missing: prefer adding binary r2u package to Dockerfile rather than install.packages at runtime
- If forest plots fail: confirm meta_adapter method selection per effect measure (PROP/OR/RR/MD/SMD/MEAN)
- If CI timeouts: favor rocker/r2u base and Buildx cache, avoid TeX PDF generation in CI

## Review comment handling
- When a reviewer flags an issue:
  1) Reproduce locally using the commands above
  2) Propose a minimal code change
  3) Add/adjust tests when feasible
  4) Link the commit diff in a reply comment summarizing the fix

## Style
- TypeScript: keep code readable, add explicit types to interfaces/functions
- R: keep functions pure, document with concise roxygen‑style headers
- Docs: update docs/decision-rules.md and README.md when behavior changes

## Done criteria
- CI green: Docker build success, Node build success, tests pass
- PR comments addressed or followed up with rationale
- No new large files committed outside LFS rules
