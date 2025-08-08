# Review guidelines for src/ (TypeScript MCP)

- Validate tool schemas in `src/index.ts` and keep them in sync with docs
- Ensure `src/config.ts` points to `scripts/entry/mcp_tools.R`
- Keep `src/r-executor.ts` safeguards: arg validation, timeouts, output caps
- Add explicit types for exported functions and interfaces
- Avoid long‑lived processes; MCP uses stdio only
