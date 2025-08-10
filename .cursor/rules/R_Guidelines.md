# R Script Development Guidelines

## Overview

This project uses R for statistical analysis, with the following key components:
- **mcp_tools.R**: Main entry point for MCP integration
- **meta_analysis_cli.R**: Command-line interface for direct usage
- **Supporting scripts**: Individual analysis components

## R Version & Package Requirements

### R Version
- Use R 4.0 or higher
- Ensure compatibility with both R 4.0 and R 4.2+ versions

### Required Packages
The project depends on these key packages:
- `meta`: Primary meta-analysis package
- `metafor`: For advanced meta-analysis functions
- `jsonlite`: For JSON parsing/serialization
- `ggplot2`: For visualization (forest plots, funnel plots)
- `rmarkdown`: For report generation (optional)
- `knitr`: For report formatting (optional)

### Package Versions
Always specify minimum package versions in package loading:
```r
if (!requireNamespace("meta", quietly = TRUE, minVersion = "6.0-0")) {
  stop("Package 'meta' (>=6.0-0) is required")
}
```

## Code Structure

### Script Organization
- Each script should have a clear purpose
- Use header comments to document script purpose and usage
- Group related functions together
- Implement error handling for all user inputs and operations

### Function Documentation
Document all functions with roxygen2-style comments:
```r
#' Function title/description
#'
#' Detailed description if needed
#'
#' @param param1 Description of param1
#' @param param2 Description of param2
#' @return Description of return value
#' @example
#' example_function("example", TRUE)
function_name <- function(param1, param2) {
  # Function implementation
}
```

## Error Handling

### Error Pattern
Use a consistent error handling pattern:
```r
tryCatch({
  # Code that might fail
}, error = function(e) {
  # Handle or report error
  return(list(status = "error", message = e$message))
})
```

### JSON Response Format
All scripts called by Node.js should return JSON-formatted responses:
```r
respond <- function(data) {
  cat(toJSON(data, auto_unbox = TRUE, pretty = TRUE))
}

error_response <- function(message) {
  respond(list(status = "error", message = message))
}
```

## Meta-Analysis Standards

### Effect Measures
- Support all standard effect measures: OR, RR, MD, SMD, HR
- Document required data format for each measure
- Provide appropriate interpretation for each measure

### Statistical Models
- Implement both fixed-effect and random-effects models
- Use REML estimation for random-effects models by default
- Report heterogeneity statistics (Q, I², τ²) with all analyses

### Visualization
- Forest plots should include study weights and confidence intervals
- Funnel plots should be available with different statistical methods
- All plots should have appropriate titles and axis labels

## Integration with MCP

### Command-Line Arguments
MCP integration is handled through command-line arguments:
1. Tool name
2. JSON-encoded arguments
3. Session path (optional)

Example:
```r
args <- commandArgs(trailingOnly = TRUE)
tool_name <- args[1]
json_args <- fromJSON(args[2])
session_path <- if (length(args) >= 3) args[3] else getwd()
```

### Tool Implementation Pattern
Implement each tool as a separate case in the main switch statement:
```r
switch(tool_name,
  "tool_name" = {
    # Tool implementation
    # Validate inputs
    # Perform analysis
    # Return results via respond() function
  },
  # Other tools...
  {
    error_response(paste("Unknown tool:", tool_name))
  }
)
```

## File Operations

### Session Directory Structure
Work with the standard session directory structure:
```
sessions/{session-id}/
├── data/       # Store uploaded data files here
├── processing/ # Store intermediate processing files
└── results/    # Store final output files (plots, reports)
```

### File Paths
Use file.path() for constructing file paths:
```r
data_file <- file.path(session_path, "data", "uploaded_data.csv")
```

### File Formats
- Save data as both CSV and RDS for efficiency
- Save plots as PNG files (or PDF for reports)
- Save reports in requested format (HTML, PDF, or plain text)

## Performance Considerations

### Large Datasets
- For large meta-analyses, use efficient data structures
- Consider memory usage when working with many studies
- Use RDS format for faster loading of processed data

### Computation Time
- Implement progress indicators for long-running operations
- Consider parallel processing for computationally intensive operations
- Cache intermediate results when appropriate

## Testing R Scripts

### Direct Testing
Test R scripts directly with sample data:
```bash
Rscript scripts/meta_analysis_cli.R analyze test-data/sample_data.csv results/ random OR
```

### Debugging
For debugging complex scripts:
```r
# Add debug output
cat(sprintf("DEBUG: variable=%s\n", variable), file=stderr())

# Or use R debugging functions
browser()  # Interactive debugging point
```

## Report Generation

### Report Templates
- Use R Markdown templates for report generation
- Include key statistical outputs and visualizations
- Provide interpretation of results based on statistical standards

### PRISMA Guidelines
- Align reports with PRISMA guidelines for meta-analysis reporting
- Include all required elements (search strategy, selection criteria, analysis methods)
- Provide appropriate citations and references