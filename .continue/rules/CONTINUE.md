# Meta-Analysis MVP Project Guide

## Project Overview

The Meta-Analysis MVP is a minimal, functional implementation for running meta-analysis through the Model Context Protocol (MCP). This project provides a streamlined way to conduct complete meta-analyses with all core functions while removing enterprise complexity.

**Key Technologies:**
- **Backend**: Node.js 18+ with TypeScript
- **Statistical Analysis**: R 4.0+ with meta/metafor packages
- **Protocol**: Model Context Protocol (MCP)
- **Deployment**: Docker-ready with minimal dependencies

**Core Features:**
- All 6 core meta-analysis functions
- File-based session management (no database required)
- Simple deployment with minimal dependencies
- Multi-session support
- Complete workflow from data upload to report generation

## Getting Started

### Prerequisites

1. **Node.js 18+**
   - [Download from nodejs.org](https://nodejs.org/)

2. **R 4.0+** with the following packages:
   - `meta`
   - `metafor`
   - `jsonlite`
   - `ggplot2` (for plots)
   - `rmarkdown` (for reports)
   - `knitr` (for reports)

### Installation

1. **Clone the repository** (if applicable)

2. **Install Node dependencies**
   ```bash
   npm install
   ```

3. **Install R packages**
   ```R
   install.packages(c("meta", "metafor", "jsonlite", "ggplot2", "rmarkdown", "knitr"))
   ```
   
   Alternatively, run the installation script:
   ```bash
   Rscript scripts/install_packages.R
   ```

4. **Build the TypeScript server**
   ```bash
   npm run build
   ```

5. **Configure environment** (optional)
   ```bash
   cp .env.example .env
   ```
   Edit the `.env` file to customize settings.

### Running the Server

**Direct run:**
```bash
npm start
```

**Using the MCP Inspector for testing:**
```bash
npm run inspector
```

### Demo Workflow

To see the complete meta-analysis workflow in action:
```bash
node demo-workflow.js
```

This demonstrates:
1. Session initialization
2. Data upload and validation
3. Meta-analysis execution
4. Forest and funnel plot generation
5. Publication bias assessment
6. Comprehensive report generation
7. Session status monitoring

## Project Structure

```
meta-analysis-mvp/
├── src/                    # TypeScript source files
│   ├── index.ts           # Main MCP server entry point
│   ├── config.ts          # Configuration management
│   ├── errors.ts          # Error handling classes
│   ├── r-executor.ts      # R script execution utilities
│   └── session-manager.ts # Session management
├── scripts/               # R analysis scripts
│   ├── mcp_tools.R        # Main R script for MCP tools
│   ├── meta_analysis_cli.R # CLI for direct R usage
│   └── ... (other R scripts)
├── sessions/              # Session data (gitignored)
├── build/                 # Compiled JavaScript (gitignored)
├── test-data/             # Sample data for testing
├── package.json           # Node.js package configuration
├── tsconfig.json          # TypeScript configuration
├── .env.example           # Example environment variables
├── Dockerfile             # Docker configuration
└── README.md              # Project documentation
```

### Key Files

- **src/index.ts**: Main entry point for the MCP server, defines available tools
- **src/session-manager.ts**: Manages meta-analysis sessions and their lifecycle
- **src/r-executor.ts**: Handles execution of R scripts and parsing results
- **scripts/mcp_tools.R**: Main R script that implements meta-analysis functionality
- **demo-workflow.js**: Demonstrates complete workflow from initialization to report generation

## Development Workflow

### Building and Running

1. **Development mode** (with auto-reload):
   ```bash
   npm run dev
   ```

2. **Production build**:
   ```bash
   npm run build
   npm start
   ```

3. **Docker deployment**:
   ```bash
   docker build -t meta-analysis-mvp .
   docker run -it --rm meta-analysis-mvp
   ```

### MCP Tool Development

The project follows the Model Context Protocol architecture:

1. **Tool Registration**: Tools are registered in `src/index.ts` with their name, description, and input schema
2. **Tool Implementation**: Most tools delegate to R scripts for statistical processing
3. **Response Handling**: Results are formatted as JSON and returned to the client

### R Script Development

When developing new R functionality:

1. Add your R function to an appropriate script in the `scripts/` directory
2. Update the main `mcp_tools.R` script to include your new function
3. Register a new tool in `src/index.ts` if needed
4. Test with the MCP Inspector or demo workflow

### Testing

1. **Using the MCP Inspector**:
   ```bash
   npm run inspector
   ```
   The inspector provides a UI to test tools interactively.

2. **Running the demo workflow**:
   ```bash
   node demo-workflow.js
   ```

3. **Direct R script testing**:
   ```bash
   Rscript scripts/meta_analysis_cli.R analyze mydata.csv results/ random OR
   ```

## Key Concepts

### Meta-Analysis Methodology

This project implements key meta-analysis techniques:

- **Effect Size Calculation**: Computing standardized effect measures (OR, RR, MD, SMD, HR)
- **Fixed and Random Effects Models**: Different approaches for combining study results
- **Heterogeneity Assessment**: Measuring between-study variability (I², Q statistic)
- **Publication Bias Evaluation**: Funnel plots, Egger's test, Begg's test, Trim and Fill
- **Forest Plots**: Visualizing study effects and overall estimates

### Session Management

Sessions are stored as directories in the `sessions/` folder:

```
sessions/
└── {session-id}/
    ├── session.json       # Session metadata
    ├── data/              # Uploaded study data
    ├── processing/        # Intermediate files
    └── results/           # Analysis outputs and plots
```

Each session represents a complete meta-analysis project with its own data and results.

### MCP Architecture

The Model Context Protocol provides a standardized way to expose tools:

1. **Tool Registration**: Define tools with their parameters and schemas
2. **Tool Invocation**: Client requests execution of a specific tool
3. **Result Communication**: Server returns structured results to the client

### R Integration

The project integrates R for statistical analysis:

1. **Script Execution**: Node.js spawns R processes to run scripts
2. **Data Exchange**: JSON is used for passing data between Node.js and R
3. **Result Parsing**: R script outputs are parsed back into JavaScript objects

## Common Tasks

### Creating a New Meta-Analysis Session

```javascript
const response = await client.callTool('initialize_meta_analysis', {
  name: 'My Meta-Analysis Project',
  study_type: 'clinical_trial',  // or 'observational', 'diagnostic'
  effect_measure: 'OR',          // or 'RR', 'MD', 'SMD', 'HR'
  analysis_model: 'random'       // or 'fixed', 'auto'
});

// Extract session ID
const sessionId = JSON.parse(response.result.content[0].text).session_id;
```

### Uploading Study Data

```javascript
// Read and encode data
const data = fs.readFileSync('data.csv', 'utf8');
const dataBase64 = Buffer.from(data).toString('base64');

// Upload to session
const response = await client.callTool('upload_study_data', {
  session_id: sessionId,
  data_format: 'csv',            // currently only 'csv' is supported
  data_content: dataBase64,
  validation_level: 'comprehensive'
});
```

**Required CSV Columns:**
- `study` - Study identifier
- `effect_size` - Calculated effect size
- `variance` - Variance of the effect size

### Running Meta-Analysis

```javascript
const response = await client.callTool('perform_meta_analysis', {
  session_id: sessionId,
  heterogeneity_test: true,
  publication_bias: true,
  sensitivity_analysis: false
});
```

### Generating Visualizations

**Forest Plot:**
```javascript
const response = await client.callTool('generate_forest_plot', {
  session_id: sessionId,
  plot_style: 'modern',          // or 'classic', 'journal_specific'
  confidence_level: 0.95
});
```

**Publication Bias Assessment:**
```javascript
const response = await client.callTool('assess_publication_bias', {
  session_id: sessionId,
  methods: ['funnel_plot', 'egger_test', 'begg_test', 'trim_fill']
});
```

### Creating Reports

```javascript
const response = await client.callTool('generate_report', {
  session_id: sessionId,
  format: 'html',                // currently 'html'/'pdf'/'text' formats
  include_code: false
});
```

## Troubleshooting

### Common Issues

#### R Script Not Found
Ensure R is installed and available in PATH. Test with:
```bash
Rscript --version
```

#### Missing R Packages
Install required packages in R:
```R
install.packages(c("meta", "metafor", "jsonlite", "ggplot2", "rmarkdown", "knitr"))
```

#### Permission Issues
Ensure the process has write permissions to the sessions directory:
```bash
chmod -R 755 sessions/
```

#### Session Not Found
Check if the session ID is correct and exists in the sessions directory.

### Debugging

1. **Check Server Logs**: Look for error messages in the console

2. **Inspect Session Files**: Examine the session directory for any issues
   ```bash
   ls -la sessions/{session-id}/
   ```

3. **Test R Scripts Directly**: Run R scripts separately to isolate issues
   ```bash
   Rscript scripts/meta_analysis_cli.R analyze mydata.csv results/ random OR
   ```

4. **Use the MCP Inspector**: Run with the inspector to see detailed request/response logs
   ```bash
   npm run inspector
   ```

## References

### Meta-Analysis Resources

- [Introduction to Meta-Analysis](https://www.meta-analysis.com/downloads/Intro_to_Meta-analysis.pdf)
- [Cochrane Handbook for Systematic Reviews](https://training.cochrane.org/handbook)

### R Packages Documentation

- [meta package](https://cran.r-project.org/web/packages/meta/index.html) - Package for meta-analysis in R
- [metafor package](https://www.metafor-project.org/doku.php) - Comprehensive meta-analysis package
- [R Markdown](https://rmarkdown.rstudio.com/) - For report generation

### MCP Documentation

- [Model Context Protocol](https://github.com/microsoft/modelcontextprotocol) - Standardized protocol for tool invocation