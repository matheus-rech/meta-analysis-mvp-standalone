# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Meta-Analysis MVP (Minimum Viable Product) that implements a Model Context Protocol (MCP) server for conducting complete meta-analyses. The system integrates TypeScript/Node.js with R statistical computing to provide comprehensive meta-analysis capabilities.

## Architecture

### Core Components

1. **MCP Server** (TypeScript/Node.js)
   - Entry point: `src/index.ts`
   - Handles MCP protocol communication via stdio
   - Routes tool calls to appropriate handlers
   - Manages sessions through file-based storage

2. **R Statistical Engine**
   - Main dispatcher: `scripts/mcp_server.R` and `scripts/mcp_tools.R`
   - Tool implementations: Individual R scripts for each analysis function
   - Uses `metafor` and `meta` packages for statistical computations

3. **Session Management**
   - File-based storage in `sessions/` directory
   - Each session has its own directory with data/, results/, and processing/ subdirectories
   - No database required - uses JSON files for metadata

## Development Commands

```bash
# Install dependencies
npm install

# Install R packages (run in R console)
install.packages(c("meta", "metafor", "jsonlite", "ggplot2", "rmarkdown", "knitr"))

# Build TypeScript
npm run build

# Run the server
npm start

# Development mode with auto-rebuild
npm run dev

# Test with MCP Inspector
npm run inspector

# Clean build artifacts
npm run clean
```

## Docker Deployment

```bash
# Build Docker image
docker build -t meta-analysis-mvp .

# Run container
docker run -it --rm meta-analysis-mvp
```

## Available MCP Tools

1. **health_check** - Verify server status
2. **initialize_meta_analysis** - Create new analysis session
3. **upload_study_data** - Upload and validate study data (CSV, Excel, RevMan)
4. **perform_meta_analysis** - Execute statistical analysis
5. **generate_forest_plot** - Create publication-ready visualizations
6. **assess_publication_bias** - Run bias assessments (funnel plots, Egger's test)
7. **generate_report** - Create comprehensive reports (HTML, PDF, Word)
8. **get_session_status** - Track session progress and workflow state

## Key Implementation Details

### R Script Execution
- The TypeScript server spawns R processes via `Rscript` command
- Communication happens through JSON serialization
- R scripts use two entry points:
  - `mcp_server.R` - Sources individual tool scripts and dispatches calls
  - `mcp_tools.R` - Alternative unified implementation
- **Updated Implementation**: Now uses `meta` R package for improved functionality
  - `meta_adapter.R` - Core functions using meta package
  - Better forest plots with customization options
  - Enhanced publication bias assessment
  - Cleaner statistical implementations
  - R Markdown report generation with `report_template.Rmd`

### New Features
- **Professional HTML Reports**: Uses R Markdown templates in `templates/` directory
- **Session Status Tracking**: `get_session_status` provides workflow progress
- **Command Line Interface**: `meta_analysis_cli.R` for direct usage
- **Demo Workflow**: `demo-workflow.js` demonstrates complete workflow

### Session Structure
```
sessions/{session-id}/
├── session.json       # Metadata
├── data/             # Uploaded study data
├── processing/       # Intermediate files
└── results/          # Analysis outputs (plots, reports)
```

### Error Handling
- Custom error classes in `src/errors.ts` (ValidationError, SessionError, RScriptError)
- R scripts return JSON with `status` field ("success" or "error")
- Comprehensive error messages passed back through MCP protocol

### Data Flow
1. MCP client sends tool request → TypeScript server
2. Server validates request and session
3. Server executes R script with JSON arguments
4. R script processes data and returns JSON result
5. Server forwards result back to MCP client

## Important Configuration

- R must be installed and available in PATH
- Sessions directory must have write permissions
- For production, set `NODE_ENV=production`
- Default paths can be overridden via environment variables:
  - `SESSIONS_DIR` - Session storage location
  - `SCRIPTS_DIR` - R scripts location

## Testing Approach

The project includes test files (`test-mvp.js`, `test-functions.js`) that simulate MCP protocol interactions. No formal test framework is configured, but the MCP Inspector (`npm run inspector`) provides interactive testing capabilities.