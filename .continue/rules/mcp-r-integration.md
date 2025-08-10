# MCP-R Integration Guide

This document provides a detailed technical guide on how the Model Context Protocol (MCP) server integrates with R for statistical meta-analysis in this project.

## Architecture Overview

The Meta-Analysis MVP uses a layered architecture that bridges Node.js/TypeScript with R:

```
┌─────────────────────┐
│ MCP Client          │
└─────────┬───────────┘
          ↓
┌─────────────────────┐
│ TypeScript MCP      │
│ Server              │
└─────────┬───────────┘
          ↓
┌─────────────────────┐
│ R Script Executor   │ ← Key integration point
└─────────┬───────────┘
          ↓
┌─────────────────────┐
│ R Scripts           │
└─────────┬───────────┘
          ↓
┌─────────────────────┐
│ Statistical         │
│ Packages (meta)     │
└─────────────────────┘
```

## Key Components

### 1. R Executor (`src/r-executor.ts`)

This module is the bridge between TypeScript and R:

```typescript
export async function executeRScript(
  args: string[],
  timeout: number = 30000
): Promise<any> {
  return new Promise((resolve, reject) => {
    const scriptPath = path.join(process.cwd(), 'scripts', 'entry', 'mcp_tools.R');
    
    const rProcess = spawn('Rscript', [scriptPath, ...args], {
      env: { ...process.env },
      cwd: process.cwd()
    });
    
    // Code to handle process I/O and timeout...
    
    rProcess.stdout.on('data', (data) => {
      stdout += data.toString();
    });
    
    rProcess.on('close', (code) => {
      // Parse JSON from R script output
      try {
        const result = JSON.parse(stdout.trim());
        resolve(result);
      } catch (parseError) {
        // Handle parsing errors...
      }
    });
  });
}
```

### 2. MCP Tools Dispatcher (`scripts/entry/mcp_tools.R`)

The entry point for all R functionality:

```r
# Dispatcher
result <- tryCatch({
  if (tool_name == "upload_study_data") {
    upload_study_data(json_args)
  } else if (tool_name == "perform_meta_analysis") {
    perform_meta_analysis(json_args)
  } else if (tool_name == "generate_forest_plot") {
    generate_forest_plot(json_args)
  } else if (tool_name == "assess_publication_bias") {
    assess_publication_bias(json_args)
  } else if (tool_name == "generate_report") {
    generate_report(json_args)
  } else if (tool_name == "get_session_status") {
    get_session_status(json_args)
  } else {
    list(status = "error", message = paste("Unknown tool:", tool_name))
  }
}, error = function(e) {
  list(status = "error", message = paste("R script error:", e$message))
})
```

### 3. Statistical Adapter (`scripts/adapters/meta_adapter.R`)

Adapts R statistical packages for use with the MCP:

```r
perform_meta_analysis_core <- function(data, method = "random", measure = "OR") {
  # Implementation using meta package
  if (measure == "OR") {
    meta_result <- metabin(
      event.e = data$events_treatment,
      n.e = data$n_treatment,
      event.c = data$events_control,
      n.c = data$n_control,
      studlab = data$study_id,
      method = meta_method,
      sm = "OR",
      random = (method == "random"),
      fixed = (method == "fixed")
    )
  }
  # More implementation...
  
  return(meta_result)
}
```

## Data Flow

The data flow between MCP and R follows this pattern:

1. **Client Request**: Client calls an MCP tool with JSON parameters
2. **TypeScript Validation**: Server validates parameters
3. **Session Resolution**: Server resolves the session path
4. **R Script Execution**: `executeRScript` is called with:
   - Tool name
   - JSON-stringified arguments
   - Session path
5. **R Processing**: The R script processes the request
6. **Result Serialization**: R returns a JSON-serialized result
7. **Response Parsing**: TypeScript parses the JSON response
8. **Client Response**: Server returns the formatted result to the client

## Communication Protocol

### TypeScript to R

Arguments are passed to R as command-line parameters:

```typescript
executeRScript([
  "tool_name",          // The MCP tool name
  JSON.stringify(args), // JSON-stringified arguments
  sessionPath           // Path to the session directory
]);
```

### R to TypeScript

R scripts return results as JSON-serialized stdout:

```r
# In R script
result <- list(
  status = "success",
  results = some_data
)

# Output as JSON
cat(toJSON(result, auto_unbox = TRUE, pretty = TRUE))
```

## Session Management

Sessions are the central organizational unit:

1. **Session Creation**: TypeScript creates a session directory
2. **Session Path**: Passed to R scripts as an argument
3. **Data Storage**: R scripts read/write to session directory
4. **Session State**: Maintained on disk for persistence

## Error Handling

Errors are handled at multiple levels:

1. **TypeScript Validation**: Catches parameter errors
2. **R Script Execution**: Catches R process errors
3. **R Error Handling**: Uses tryCatch for internal R errors
4. **JSON Parsing**: Handles malformed JSON responses

All errors are transformed into a consistent format:

```typescript
{
  status: "error",
  error: "Error message",
  details: { /* Additional context */ }
}
```

## Performance Considerations

1. **Process Spawning**: Each R operation spawns a separate process
2. **Timeouts**: Default timeout prevents hanging processes
3. **Result Size**: Large results are handled with file references
4. **Cleanup**: R processes are tracked and cleaned up on shutdown

## Implementation Examples

### Example 1: Performing Meta-Analysis

**TypeScript side**:
```typescript
const sessionId = args.session_id as string;
const sessionPath = sessionManager.getSessionPath(sessionId);
const result = await executeRScript([
  "perform_meta_analysis", 
  JSON.stringify(args),
  sessionPath
]);
```

**R side**:
```r
perform_meta_analysis <- function(args) {
  session_path <- args$session_path
  
  # Load data
  processed_data_path <- file.path(session_path, "processing", "processed_data.rds")
  loaded_data <- readRDS(processed_data_path)
  
  # Perform analysis
  meta_result <- perform_meta_analysis_core(loaded_data, method, measure)
  
  # Save results
  results_dir <- file.path(session_path, "results")
  if (!dir.exists(results_dir)) {
    dir.create(results_dir, recursive = TRUE)
  }
  saveRDS(meta_result, file.path(results_dir, "analysis_results.rds"))
  
  # Return summary
  list(
    status = "success",
    overall_effect = as.numeric(pooled_effect),
    # more fields...
  )
}
```

### Example 2: Generating Visualizations

**TypeScript side**:
```typescript
const result = await executeRScript([
  "generate_forest_plot", 
  JSON.stringify({
    session_id: sessionId,
    plot_style: "modern",
    confidence_level: 0.95
  }),
  sessionPath
]);
```

**R side**:
```r
generate_forest_plot <- function(args) {
  session_path <- args$session_path
  plot_style <- args$plot_style
  
  # Load analysis results
  results_path <- file.path(session_path, "results", "analysis_results.rds")
  meta_result <- readRDS(results_path)
  
  # Generate plot
  output_file <- file.path(session_path, "results", "forest_plot.png")
  generate_forest_plot_core(meta_result, output_file, plot_style = plot_style)
  
  # Return path to generated file
  list(
    status = "success",
    plot_file = "forest_plot.png",
    # more metadata...
  )
}
```

## Best Practices

1. **Minimize Process Creation**: Group related R operations when possible
2. **Use Adapters**: Keep statistical code separate from MCP interface code
3. **File-Based Communication**: Use files for large data/results
4. **Error Context**: Include helpful context in error messages
5. **Validation**: Validate inputs at both TypeScript and R levels
6. **Logging**: Use `print()` statements in R for debugging
7. **Testing**: Test R scripts independently before integrating