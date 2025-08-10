# Meta-Analysis MVP Cursor Rules

This file contains structured rules for working with the Meta-Analysis MVP codebase, focusing specifically on the MCP server implementation and R integration.

## TypeScript MCP Server Rules

### Rule: MCP Tool Definition Structure
When defining a new MCP tool in `src/index.ts`, always follow this structure:
```typescript
{
  name: "tool_name",
  description: "Clear description of what the tool does",
  inputSchema: {
    type: "object",
    properties: {
      session_id: { type: "string" },
      // Other parameters with proper types and descriptions
    },
    required: ["session_id", /* other required parameters */]
  },
}
```

### Rule: Tool Validation Implementation
Always implement validation for new tools in the `toolValidationSchemas` object:
```typescript
tool_name: (args: any) => {
  if (!args) throw new ValidationError("Arguments are required");
  if (!args.session_id || typeof args.session_id !== 'string') {
    throw new ValidationError("Parameter 'session_id' is required and must be a string");
  }
  // Validate other parameters
}
```

### Rule: Error Handling Standards
Use the custom error types from `src/errors.ts` and handle them consistently:
- `ValidationError`: For invalid parameters
- `SessionError`: For session-related issues
- `RExecutionError`: For R script execution problems

All errors should be handled through the `handleError` function to ensure consistent formatting.

### Rule: R Script Execution
When executing R scripts from TypeScript, always use the `executeRScript` function with proper error handling:
```typescript
try {
  const result = await executeRScript([
    "tool_name", 
    JSON.stringify(args),
    sessionPath
  ], timeout);
  
  return {
    content: [{
      type: "text",
      text: JSON.stringify(result, null, 2)
    }]
  };
} catch (error) {
  const errorResponse = handleError(error);
  return {
    content: [{
      type: "text",
      text: JSON.stringify(errorResponse, null, 2)
    }]
  };
}
```

## R Script Implementation Rules

### Rule: R Tool Function Structure
When implementing a new R function for an MCP tool in `scripts/tools/`, follow this pattern:
```R
tool_name <- function(args) {
  # Extract parameters
  session_path <- args$session_path
  
  # Load session configuration if needed
  session_config_path <- file.path(session_path, "session.json")
  session_config <- fromJSON(session_config_path)
  
  # Implementation logic
  
  # Return results as a properly structured list
  list(
    status = "success",
    # Other result fields
  )
}
```

### Rule: Error Handling in R
Handle errors in R scripts with tryCatch and return properly structured error messages:
```R
tryCatch({
  # Implementation
  
  # Return success result
  list(status = "success", results = results_data)
}, error = function(e) {
  list(
    status = "error",
    message = paste("Error in tool_name:", e$message),
    details = list(
      # Any relevant details about the error context
    )
  )
})
```

### Rule: Session Data Management
When working with session data in R scripts, follow these conventions:
1. Load session config from `session.json`
2. Load data from `data/` or `processing/` directory
3. Save results to `results/` directory
4. Create directories if they don't exist

### Rule: R Package Dependencies
Always document R package dependencies at the top of each script:
```R
# Required packages: meta, metafor, jsonlite
suppressPackageStartupMessages({
  library(meta)
  library(metafor)
  library(jsonlite)
})
```

## Integration Rules

### Rule: Data Serialization
When passing data between TypeScript and R:
1. Use JSON for configuration and metadata
2. Use RDS files for R objects
3. Use base64 encoding for binary data
4. Document the expected data format

### Rule: MCP Tool to R Script Mapping
When adding a new tool:
1. Add the tool definition in `src/index.ts`
2. Implement the validation in `toolValidationSchemas`
3. Create the R implementation in `scripts/tools/`
4. Update the dispatcher in `scripts/entry/mcp_tools.R`

### Rule: Session Management
Every tool that uses a session must:
1. Validate the session ID exists
2. Get the session path using `sessionManager.getSessionPath()`
3. Pass the session path to the R script
4. Update session status as appropriate

### Rule: Result Formatting
Results from R should be formatted consistently:
1. Use a top-level `status` field ("success" or "error")
2. Include a `message` field for human-readable descriptions
3. Structure data fields logically and consistently
4. Use clear, descriptive field names

## Testing and Development Rules

### Rule: R Script Testing
Test R scripts independently before integrating:
```bash
# Test directly with Rscript
Rscript scripts/entry/mcp_tools.R tool_name '{"param":"value"}' /path/to/test/session
```

### Rule: TypeScript Testing
Test MCP tools using the inspector:
```bash
npm run inspector
```

### Rule: Error Handling Testing
Test both successful cases and error cases for each tool.

### Rule: Documentation Standards
Document all MCP tools with:
1. Clear description
2. All parameters with types and descriptions
3. Example usage
4. Expected response format