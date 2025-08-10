# Meta-Analysis MVP Project Guide

This document provides a comprehensive guide to understanding and working with the Meta-Analysis MVP project, a server implementation of the Model Context Protocol (MCP) that integrates with R for statistical analysis.

## Project Overview

The Meta-Analysis MVP is a minimal, functional implementation of a server that enables conducting meta-analyses through the Model Context Protocol (MCP). It connects a TypeScript/Node.js server to R statistical capabilities, allowing for sophisticated meta-analysis workflows without requiring a database or complex infrastructure.

### Key Technologies

- **Server**: Node.js (18+) with TypeScript
- **Statistical Engine**: R (4.0+) with meta-analysis packages
- **Protocol**: Model Context Protocol (MCP)
- **Session Management**: File-based
- **Deployment**: Docker-ready

### High-Level Architecture

The system follows a layered architecture:
1. **MCP Server Layer**: Handles protocol communication
2. **Business Logic Layer**: Session management and workflow
3. **R Integration Layer**: Executes statistical scripts
4. **File Storage Layer**: Persists sessions and results

## Getting Started

### Prerequisites

1. **Node.js 18+**: Required for the TypeScript server
2. **R 4.0+**: Required for statistical analysis
3. **R Packages**:
   - Core: `meta`, `metafor`, `jsonlite`
   - Visualization: `ggplot2`
   - Reporting: `rmarkdown`, `knitr`, `DT`
   - Data Import: `readxl`, `base64enc`

### Installation

1. Clone the repository
2. Install Node.js dependencies:
   ```bash
   npm install
   ```
3. Install required R packages:
   ```R
   install.packages(c("meta", "metafor", "jsonlite", "ggplot2", 
                     "rmarkdown", "knitr", "readxl", "base64enc", "DT"))
   ```

### Building the Project

Build the TypeScript code:
```bash
npm run build
```

### Running the Server

Start the server directly:
```bash
npm start
```

Or use the MCP Inspector for interactive testing:
```bash
npm run inspector
```

## Project Structure

### Core Components

- **TypeScript Server**
  - `src/index.ts`: Main entry point and MCP server definition
  - `src/r-executor.ts`: Bridge between Node.js and R
  - `src/session-manager.ts`: Manages analysis sessions
  - `src/config.ts`: Configuration management
  - `src/errors.ts`: Error handling and types

- **R Scripts**
  - `scripts/entry/mcp_tools.R`: Main entry point for R scripts
  - `scripts/tools/`: Individual tool implementations
  - `scripts/adapters/`: Adapters for statistical packages
  - `scripts/utils/`: Utility functions

- **Project Structure**
  ```
  meta-analysis-mvp/
  ├── src/                   # TypeScript source files
  ├── scripts/               # R analysis scripts
  │   ├── entry/             # Entry points
  │   ├── tools/             # Tool implementations
  │   ├── adapters/          # Package adapters
  │   └── utils/             # Utility functions
  ├── sessions/              # Session data (gitignored)
  ├── build/                 # Compiled JavaScript
  ├── templates/             # Report templates
  ├── .env.example           # Environment variables example
  └── package.json           # Node.js package info
  ```

### Session Management

Sessions are stored as directories:
```
sessions/
└── {session-id}/
    ├── session.json       # Session metadata
    ├── data/              # Uploaded study data
    ├── processing/        # Intermediate files
    └── results/           # Analysis outputs
```

## Development Workflow

### Server Development (TypeScript)

1. **Adding New MCP Tools**
   - Define tool schema in `src/index.ts`
   - Add validation in `toolValidationSchemas`
   - Implement handler in `CallToolRequestSchema` handler

2. **Error Handling**
   - Custom error types in `src/errors.ts`
   - Use `handleError` to format errors

3. **Configuration Management**
   - Modify `src/config.ts` for configuration options
   - Use environment variables with `.env` file

### R Script Development

1. **Implementation Pattern**
   - Create a new R script in `scripts/tools/`
   - Follow the standard function pattern:
     ```R
     tool_name <- function(args) {
       # Extract parameters
       session_path <- args$session_path
       
       # Implementation
       
       # Return results as a list
       list(
         status = "success",
         # other fields...
       )
     }
     ```

2. **Connecting to MCP**
   - Add your function to `scripts/entry/mcp_tools.R`
   - Map it in the dispatcher section

3. **Testing R Functions**
   - Test directly using Rscript
   - Use `utils/test_scripts.R` for isolated testing

### Building and Testing

1. **Development Mode**
   ```bash
   npm run dev
   ```

2. **Testing**
   - Use the demo workflow: `node demo-workflow.js`
   - Use the MCP Inspector: `npm run inspector`

3. **Code Linting**
   ```bash
   npm run lint
   ```

## Key Concepts

### Meta-Analysis Workflow

The meta-analysis process follows these steps:
1. **Initialize Meta-Analysis**: Set up analysis parameters
2. **Upload Study Data**: Provide and validate data
3. **Perform Meta-Analysis**: Run statistical analysis
4. **Generate Visualizations**: Create forest and funnel plots
5. **Assess Publication Bias**: Check for bias in results
6. **Generate Reports**: Create comprehensive reports

### Session-Based Architecture

The system uses a session-based architecture:
- Each analysis has a unique session ID
- Sessions persist on disk for resilience
- All operations are tied to a session

### MCP Tool Architecture

Tools follow the Model Context Protocol standard:
- Each tool has a defined schema
- Tools take JSON input and produce JSON output
- Tools are stateless, with state stored in the session

### R Script Execution Model

R integration follows these principles:
- Scripts are executed in separate processes
- Communication is through JSON
- Timeouts prevent hanging processes
- Results are captured and parsed back to JSON

## Common Tasks

### Adding a New Meta-Analysis Feature

1. **Define the Tool in TypeScript**
   ```typescript
   // In src/index.ts
   {
     name: "new_analysis_feature",
     description: "Description of the new feature",
     inputSchema: {
       type: "object",
       properties: {
         session_id: { type: "string" },
         // other parameters...
       },
       required: ["session_id", /* other required params */]
     },
   }
   ```

2. **Add Validation**
   ```typescript
   // In toolValidationSchemas
   new_analysis_feature: (args: any) => {
     if (!args) throw new ValidationError("Arguments are required");
     if (!args.session_id || typeof args.session_id !== 'string') {
       throw new ValidationError("Parameter 'session_id' is required and must be a string");
     }
     // Validate other parameters...
   }
   ```

3. **Create R Implementation**
   ```R
   # In scripts/tools/new_analysis_feature.R
   new_analysis_feature <- function(args) {
     session_path <- args$session_path
     
     # Implementation...
     
     return(list(
       status = "success",
       results = results_data
     ))
   }
   ```

4. **Connect in MCP Tools Dispatcher**
   ```R
   # In scripts/entry/mcp_tools.R
   source(file.path(scripts_root, "tools", "new_analysis_feature.R"))
   
   # In the dispatcher
   if (tool_name == "new_analysis_feature") {
     new_analysis_feature(json_args)
   }
   ```

### Working with Session Data

To access session data from R:

```R
# Load session configuration
session_config_path <- file.path(session_path, "session.json")
session_config <- fromJSON(session_config_path)

# Load processed data
processed_data_path <- file.path(session_path, "processing", "processed_data.rds")
processed_data <- readRDS(processed_data_path)

# Save results
results_dir <- file.path(session_path, "results")
if (!dir.exists(results_dir)) {
  dir.create(results_dir, recursive = TRUE)
}
saveRDS(results, file.path(results_dir, "analysis_results.rds"))
```

### Running R Scripts from TypeScript

```typescript
import { executeRScript } from "./r-executor.js";

// Execute R script with arguments
const result = await executeRScript([
  "tool_name", 
  JSON.stringify({ param1: "value1", param2: "value2" }),
  sessionPath
]);
```

## Troubleshooting

### Common Issues

#### R Script Execution Errors

**Problem**: R script fails to execute or returns an error.

**Solutions**:
- Check R is installed and available in PATH: `Rscript --version`
- Verify required R packages are installed
- Check script paths in error messages
- Review R error output in server logs

#### Missing R Packages

**Problem**: Error about missing R packages.

**Solution**: Install required packages in R:
```R
install.packages(c("meta", "metafor", "jsonlite", "ggplot2", 
                 "rmarkdown", "knitr", "readxl", "base64enc", "DT"))
```

#### Session Not Found

**Problem**: "Session not found" error when calling tools.

**Solutions**:
- Verify the session ID is correct
- Check permissions on the sessions directory
- Ensure the session was properly initialized

#### R Script Timeout

**Problem**: R script execution times out.

**Solutions**:
- Increase timeout in `executeRScript` call
- Optimize R code for performance
- Check for infinite loops or hung processes

### Debugging Tips

1. **Debugging TypeScript Server**
   - Check server logs (written to stderr)
   - Use `console.error()` for debugging
   - Add additional logging in key areas

2. **Debugging R Scripts**
   - Add `print()` statements in R code
   - Test R scripts directly using Rscript
   - Use `sessionInfo()` to check R environment

3. **Checking Session Data**
   - Examine session files in the sessions directory
   - Check JSON syntax in session.json
   - Verify file permissions

## References

### Documentation

- [Model Context Protocol (MCP) Documentation](https://github.com/centerofci/model-context-protocol)
- [R Meta Package Documentation](https://cran.r-project.org/web/packages/meta/meta.pdf)
- [Metafor Package Documentation](https://cran.r-project.org/web/packages/metafor/metafor.pdf)

### Key API References

- **MCP Server SDK**: `@modelcontextprotocol/sdk`
- **Meta Package**: Meta-analysis in R
- **Metafor Package**: Comprehensive meta-analysis in R

### Meta-Analysis Resources

- [Cochrane Handbook for Systematic Reviews](https://training.cochrane.org/handbook)
- [PRISMA Statement](http://www.prisma-statement.org/)
- [Meta-Analysis Concepts](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3049418/)

### Development Tools

- [TypeScript Documentation](https://www.typescriptlang.org/docs/)
- [R Programming Language](https://www.r-project.org/documentation/)
- [Docker Documentation](https://docs.docker.com/)