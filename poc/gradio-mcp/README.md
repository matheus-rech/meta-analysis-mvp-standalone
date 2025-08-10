PoC: Gradio chat UI that talks to the TS MCP server via Python MCP SDK.

- Keeps core TS server unchanged
- Uses rpy2 and reticulate to enable R<->Python interop in the PoC

Quick start (local):

```bash
npm ci && npm run build
python -m venv .venv && source .venv/bin/activate
pip install -r poc/gradio-mcp/requirements-poc.txt
python poc/gradio-mcp/app.py
```

Docker build:

```bash
docker build -f poc/gradio-mcp/Dockerfile.poc -t meta-analysis-poc .
docker run -p 7860:7860 meta-analysis-poc
```
