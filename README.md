# Meta-Analysis MVP

A minimal, functional MVP for running meta-analysis through the Model Context Protocol (MCP). This simplified version removes all enterprise complexity while preserving the core functionality for conducting complete meta-analyses.

## Features

- ✅ All 6 core meta-analysis functions
- ✅ File-based session management (no database required)
- ✅ Simple deployment with minimal dependencies
- ✅ Multi-session support
- ✅ Docker-ready

## Requirements

- Node.js 18+ 
- R 4.0+ with the following packages:
  - `meta`, `metafor`, `jsonlite`
  - `ggplot2` (for plots), `rmarkdown`, `knitr` (for reports)
  - `readxl` (Excel import), `base64enc` (binary uploads), `DT` (report tables)

## Quick Start

### 1. Install Dependencies

```bash
# Install Node dependencies
npm install

# Install R packages (run in R console)
install.packages(c("meta", "metafor", "jsonlite", "ggplot2", "rmarkdown", "knitr", "readxl", "base64enc", "DT"))
```

### 2. Build the TypeScript Server

```bash
npm run build
```

### 3. Run the Server

```bash
# Direct run
npm start

# Or use the MCP Inspector for testing
npm run inspector
```

## Available Tools

### 1. `health_check`
Check if the server is running properly.

### 2. `initialize_meta_analysis`
Start a new meta-analysis session.

**Parameters:**
- `name`: Project name
- `study_type`: "clinical_trial", "observational", or "diagnostic"
- `effect_measure`: "OR", "RR", "MD", "SMD", or "HR"
- `analysis_model`: "fixed", "random", or "auto"

### 3. `upload_study_data`
Upload and validate study data.

**Parameters:**
- `session_id`: Session ID from initialization
- `data_format`: "csv", "excel", or "revman"
- `data_content`: Base64 encoded data
- `validation_level`: "basic" or "comprehensive"

### 4. `perform_meta_analysis`
Execute the meta-analysis.

**Parameters:**
- `session_id`: Session ID
- `heterogeneity_test`: boolean (default: true)
- `publication_bias`: boolean (default: true)
- `sensitivity_analysis`: boolean (default: false)

### 5. `generate_forest_plot`
Create forest plots.

**Parameters:**
- `session_id`: Session ID
- `plot_style`: "classic", "modern", or "journal_specific"
- `confidence_level`: number (default: 0.95)
- `custom_labels`: object (optional)

### 6. `assess_publication_bias`
Assess publication bias.

**Parameters:**
- `session_id`: Session ID
- `methods`: array of ["funnel_plot", "egger_test", "begg_test", "trim_fill"]

### 7. `generate_report`
Generate comprehensive reports.

**Parameters:**
- `session_id`: Session ID
- `format`: "html", "pdf", or "word"
- `include_code`: boolean (default: false)
- `journal_template`: string (optional)

### 8. `get_session_status`
Get the current status of a meta-analysis session.

**Parameters:**
- `session_id`: Session ID

**Returns:**
- Current workflow stage
- Completed analysis steps
- List of generated files
- Next recommended actions

## Configuration

Copy `.env.example` to `.env` to customize settings:

```bash
cp .env.example .env
```

Available settings:
- `NODE_ENV`: development or production
- `SESSIONS_DIR`: Directory for session data (default: ./sessions)
- `SCRIPTS_DIR`: Directory for R scripts (default: ./scripts)

## Docker Deployment

```bash
# Build the Docker image
docker build -t meta-analysis-mvp .

# Run the container
docker run -it --rm meta-analysis-mvp
```

### Use with Claude Desktop (Dockerized MCP)

Avoid local R setup by using the Dockerized MCP server via stdio.

1) Build or pull the image
```bash
docker build -t meta-analysis-mvp .
# or pull your registry image if available: docker pull <account>/meta-analysis-mvp:latest
```

2) Configure Claude Desktop to use the wrapper `scripts/mcp-docker.sh`:

```json
{
  "mcpServers": {
    "meta-analysis-mvp": {
      "command": "/ABS/PATH/meta-analysis-mvp-standalone/scripts/mcp-docker.sh",
      "args": [],
      "transport": "stdio"
    }
  }
}
```

Optional environment variables:
- `SESSIONS_DIR`: host directory to persist sessions (mounted to `/app/sessions`)
- `MCP_IMAGE`/`MCP_TAG`: override image name/tag used by the wrapper

## Project Structure

```
meta-analysis-mvp/
├── src/                    # TypeScript source files
│   ├── index.ts           # Main MCP server
│   ├── config.ts          # Configuration
│   ├── errors.ts          # Error handling
│   ├── r-executor.ts      # R script execution
│   └── session-manager.ts # Session management
├── scripts/               # R analysis scripts
├── sessions/              # Session data (gitignored)
├── build/                 # Compiled JavaScript (gitignored)
├── package.json
├── tsconfig.json
├── .env.example
├── .gitignore
├── Dockerfile
└── README.md
```

## Session Management

Sessions are stored as directories in the `sessions/` folder:

```
sessions/
└── {session-id}/
    ├── session.json       # Session metadata
    ├── data/             # Uploaded study data
    ├── processing/       # Intermediate files
    └── results/          # Analysis outputs
```

## Development

```bash
# Watch mode for development
npm run dev

# Clean build directory
npm run clean
```

## Command Line Interface (CLI)

In addition to the MCP server, this package now includes a standalone CLI for direct R usage:

```bash
# Perform meta-analysis
Rscript scripts/meta_analysis_cli.R analyze data.csv output_dir/ [method] [measure]

# Generate forest plot
Rscript scripts/meta_analysis_cli.R forest data.csv output_dir/ ["Plot Title"]

# Generate funnel plot  
Rscript scripts/meta_analysis_cli.R funnel data.csv output_dir/ ["Plot Title"]

# Assess publication bias
Rscript scripts/meta_analysis_cli.R bias data.csv output_dir/
```

### CLI Examples

```bash
# Random effects meta-analysis with OR
Rscript scripts/meta_analysis_cli.R analyze mydata.csv results/ random OR

# Fixed effects with mean difference
Rscript scripts/meta_analysis_cli.R analyze mydata.csv results/ fixed MD

# Generate visualizations
Rscript scripts/meta_analysis_cli.R forest mydata.csv results/ "COVID-19 Treatment Effects"
Rscript scripts/meta_analysis_cli.R funnel mydata.csv results/
```

## Enhanced Features

This implementation now uses the `meta` R package for improved functionality:

- **Better Forest Plots**: Enhanced visualization with customizable styles (classic, modern, journal-specific)
- **Improved Statistical Methods**: Using meta package's optimized algorithms
- **Additional Plot Customization**: Color schemes, spacing, and labeling options
- **Direct CSV Support**: CLI can work with CSV files directly without base64 encoding
- **Personalized HTML Reports**: Professional reports generated with R Markdown
- **Session Status Tracking**: Monitor workflow progress and get recommendations
- **Demo Workflow Script**: Run `node demo-workflow.js` to see complete workflow

## Demo Workflow

To see the complete meta-analysis workflow in action:

```bash
# Build the server first
npm run build

# Run the demo
node demo-workflow.js
```

This will demonstrate:
1. Session initialization
2. Data upload and validation
3. Meta-analysis execution
4. Forest and funnel plot generation
5. Publication bias assessment
6. Comprehensive report generation
7. Session status monitoring

## Troubleshooting

### R Script Not Found
Ensure R is installed and available in PATH. Test with:
```bash
Rscript --version
```

### Missing R Packages
Install required packages in R:
```R
install.packages(c("meta", "metafor", "jsonlite", "ggplot2", "rmarkdown", "knitr", "readxl", "base64enc", "DT"))
```

### Permission Issues
Ensure the process has write permissions to the sessions directory:
```bash
chmod -R 755 sessions/
```

## License

MIT License - See LICENSE file for details.