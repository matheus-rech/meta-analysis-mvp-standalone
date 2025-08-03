# TypeScript Development Guidelines

## Coding Standards

### Naming Conventions
- **Interfaces**: Use PascalCase (e.g., `SessionConfig`)
- **Types**: Use PascalCase (e.g., `AnalysisModel`)
- **Functions**: Use camelCase (e.g., `executeRScript`)
- **Variables**: Use camelCase (e.g., `sessionId`)
- **Constants**: Use UPPER_SNAKE_CASE for true constants (e.g., `MAX_SESSIONS`)
- **Files**: Use kebab-case (e.g., `session-manager.ts`)

### Code Style
- Use explicit types rather than relying on type inference for public APIs
- Avoid `any` type; use specific types or `unknown` when type is truly unknown
- Prefer interfaces over type aliases for object types
- Use async/await instead of raw promises for better readability
- Include proper error handling for all asynchronous operations

## Project Structure

### Component Organization
- **config.ts**: Application configuration
- **errors.ts**: Error classes and error handling utilities
- **index.ts**: Main entry point and MCP server setup
- **r-executor.ts**: R script execution utilities
- **session-manager.ts**: Session management

### Adding New Features
When adding new features:

1. Determine if it fits into an existing component or requires a new file
2. For MCP tools:
   - Add the tool definition to the `tools` array in `index.ts`
   - Implement the tool handler in the appropriate location
   - Consider if R script functionality needs to be added

## Error Handling

### Error Classes
Use the appropriate error class from `errors.ts`:
- `AppError`: Base error class
- `ValidationError`: For input validation failures
- `RScriptError`: For R script execution failures
- `SessionError`: For session-related issues

### Error Patterns
```typescript
// Example error handling pattern
try {
  // Operation that might fail
} catch (error) {
  if (error instanceof ValidationError) {
    // Handle validation errors
  } else if (error instanceof RScriptError) {
    // Handle R script errors
  } else {
    // Convert unknown errors to AppError
    throw new AppError(`Unexpected error: ${error.message}`);
  }
}
```

## TypeScript Configuration

The project uses the following TypeScript configuration in `tsconfig.json`:
- Target: ES modules
- Module: Node16
- Strict type checking
- ESM module format

When making changes to TypeScript configuration, ensure all developers update their environments accordingly.

## Working with MCP Tools

### Tool Registration Pattern
```typescript
{
  name: "tool_name",
  description: "Description of what the tool does",
  inputSchema: {
    type: "object",
    properties: {
      param1: { type: "string", description: "Parameter description" },
      param2: { type: "boolean", default: false }
    },
    required: ["param1"]
  }
}
```

### Tool Handler Pattern
```typescript
case "tool_name": {
  if (!args) {
    throw new ValidationError("Arguments are required");
  }
  
  // Extract and validate parameters
  const param1 = args.param1 as string;
  const param2 = args.param2 as boolean ?? false;
  
  // Perform operation
  const result = await someFunction(param1, param2);
  
  // Return formatted response
  return {
    content: [{
      type: "text",
      text: JSON.stringify({
        status: 'success',
        data: result
      }, null, 2)
    }]
  };
}
```

## Session Management

When working with the session manager, follow these patterns:

### Creating Sessions
```typescript
const session = await sessionManager.createSession({
  name: "Session name",
  studyType: "clinical_trial",
  effectMeasure: "OR",
  analysisModel: "random"
});
```

### Verifying Sessions
Always verify a session exists before performing operations:
```typescript
if (!await sessionManager.sessionExists(sessionId)) {
  throw new ValidationError(`Session not found: ${sessionId}`);
}
```

## Testing

### Manual Testing
- Use the MCP Inspector (`npm run inspector`) for interactive testing
- Test your tool with various inputs including edge cases

### Debugging
- Use `console.log` for temporary debugging
- Consider adding verbose logging in development mode
- Check R script error messages in stderr output