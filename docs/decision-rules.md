# Meta-Analysis Decision Rules and Defaults

This document captures the conventions the MCP server uses to choose statistical methods, normalize data, and render plots. Clients can override defaults via tool parameters (see generate_forest_plot `plot_options`).

## Data ingestion and normalization
- Excel: When uploading `.xlsx`, an optional `sheet_name` can be provided; defaults to the first sheet. Empty rows/columns are dropped.
- Column names: trimmed, lowercased, spaces replaced by `_`. Original labels preserved for study labels when possible (e.g., `Author`).
- Numeric coercion: locale commas in numeric-looking columns are converted to dots.
- Multi-outcome: Multiple sheets treated as distinct outcomes; stored within the session.

## Accepted schemas per analysis type
- PROP (single-arm proportions): columns `events|event`, `n`, optional `Author`, subgroup columns (e.g., `location`).
- Binary two-arm: either
  - compact e/c: `event.e`, `n.e`, `event.c`, `n.c`, `Author`, `Year` (optional), or
  - treatment/control: `event1`, `n1`, `event2`, `n2` (+ labels mapped appropriately).
- Continuous two-arm: either
  - compact e/c: `n.e`, `mean.e`, `sd.e`, `n.c`, `mean.c`, `sd.c`, or
  - treatment/control: `n_treatment`, `mean_treatment`, `sd_treatment`, `n_control`, `mean_control`, `sd_control`.
- Effect size (generic):
  - TE + seTE: `TE|yi` (log measure or raw for MD/SMD), `seTE|se|vi` (if `vi` given, uses sqrt), optional `n.e`, `n.c`, `Author`.
  - CI-based: `effect`, `lower`, `upper` (ratio measures supplied as non-log), optional `n.e`, `n.c`, `Author`.
- Single means (MEAN): `n`, `mean`, `sd`, `Author`; optional quantiles for estimation (see below).

## Method selection and transformations
- PROP (metaprop):
  - Preferred method: `GLMM`.
  - Transformation (sm) auto-selected:
    - extremes present (any p ≤ 0 or ≥ 1): `PFT`
    - mean proportion < 0.2 or > 0.8: `PLOGIT`
    - otherwise: `PRAW`
- Binary (metabin): default `method="MH"`, `method.tau="REML"`; `sm` default `OR`.
- Continuous two-arm (metacont): default `method.tau="REML"`, `sm` default `MD` (use `SMD` when scales differ).
- Effect size (metagen):
  - If CI provided: derive `TE` and `seTE` via log transform for ratio measures; or raw for MD/SMD.
  - Default `method.tau="REML"`; `sm` one of `OR|RR|HR|MD|SMD|ROM|RD`.
- Single means (metamean): default `sm="MRAW"`; use `"MLN"` when the user indicates log-normal data.

## Estimating mean/SD from medians and quantiles (MEAN)
- Uses `estmeansd` when `mean`/`sd` missing but any of: (n, median, min, max) / (n, median, q1, q3) / (n, median, min, max, q1, q3).
- Selection:
  - If user indicates non-normal distribution: `bc.mean.sd()`
  - If user indicates normal distribution: `mln.mean.sd()`
- Estimated values are added to the dataset and persisted in the session processing directory.

## Plot rendering defaults and customization
- All plots accept `plot_options` overrides. Defaults by analysis type:
  - PROP: `pscale=100`, leftcols `[studlab, events, n, effect, ci, w.random]`, `xlab="Proportion (%)"`, classic style.
  - Binary: layout `Revman5`, leftcols `[studlab, Year, event.e, n.e, event.c, n.c, w.random, effect, ci]`, show heterogeneity stats.
  - Continuous two-arm: leftcols `[studlab, Year, mean.e, sd.e, n.e, mean.c, sd.c, n.c, w.random, effect, ci]`, optional prediction band.
  - Single means: leftcols `[studlab, Year, n, mean, sd, w.random, ci]`, `xlab` from user.
  - Effect size: two presets: with or without `n.e/n.c` columns.
- Common options: `layout`, `sortvar`, `lab.e/lab.c`, `label.left/right`, `digits`, `col.square/lines`, `col.diamond/lines`, `print.Q`, `print.pval.Q`, `print.tau.ci`, `overall.hetstat`, `prediction`, `colgap`, `colgap.forest`.

## Subgroups
- Subgroup analyses (e.g., by `location`) are supported where applicable via a `byvar` parameter (to be added to tool args). Forest plots can render subgroup labels and test subgroup differences.

## Tools
- `initialize_meta_analysis`: sets `effect_measure` and `analysis_model` (fixed|random|auto).
- `upload_study_data`: accepts `csv|excel|revman` + base64 content; optional `sheet_name`. Applies normalization and validation, persists processed data.
- `perform_meta_analysis`: dispatches to appropriate meta function per `effect_measure`.
- `generate_forest_plot`: renders plot with defaults per analysis type; accepts `plot_options` overrides.
- `assess_publication_bias`: uses package-appropriate tests; warns for low k.
- `generate_report`: renders Rmd with results, plots, and Cochrane-aligned guidance.
- `get_session_status`: reports workflow state and artifacts.
- (Planned) `preview_study_data`, `list_excel_sheets` for inspection.

## Cochrane-aligned guidance
- Heterogeneity interpretation, publication bias cautions, and educational content are included via `cochrane_guidance.R` and injected into results and reports where relevant.

## Security and limits
- Max upload size: 50MB (decoded). CSV rows capped at ~10k for safety.
- JSON output capped at 10MB.
- R processes timeout by default at 45s (configurable per call).
