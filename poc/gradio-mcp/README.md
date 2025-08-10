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

## REST API examples (curl)

Health:
```bash
curl -s http://localhost:7860/api/health | jq
```

Initialize session:
```bash
curl -s -X POST http://localhost:7860/api/initialize_meta_analysis \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Demo",
    "study_type": "clinical_trial",
    "effect_measure": "OR",
    "analysis_model": "random"
  }' | jq
```

Upload CSV using `csv_text` (server will base64 it):
```bash
SESSION_ID=... # replace with the id from initialize step
CSV='study_id,effect_size,se\nS1,0.2,0.1\nS2,0.1,0.12\nS3,0.3,0.15\n'
curl -s -X POST http://localhost:7860/api/upload_study_data \
  -H 'Content-Type: application/json' \
  -d "{\n    \"session_id\": \"$SESSION_ID\",\n    \"data_format\": \"csv\",\n    \"csv_text\": \"$CSV\",\n    \"validation_level\": \"basic\"\n  }" | jq
```

Perform analysis:
```bash
curl -s -X POST http://localhost:7860/api/perform_meta_analysis \
  -H 'Content-Type: application/json' \
  -d '{
    "session_id": "'$SESSION_ID'",
    "heterogeneity_test": true,
    "publication_bias": true,
    "sensitivity_analysis": false
  }' | jq
```

Forest plot:
```bash
curl -s -X POST http://localhost:7860/api/generate_forest_plot \
  -H 'Content-Type: application/json' \
  -d '{
    "session_id": "'$SESSION_ID'",
    "plot_style": "classic",
    "confidence_level": 0.95
  }' | jq
```

Report generation:
```bash
curl -s -X POST http://localhost:7860/api/generate_report \
  -H 'Content-Type: application/json' \
  -d '{
    "session_id": "'$SESSION_ID'",
    "format": "html",
    "include_code": false
  }' | jq
```

## fastmcp usage (Python client)

```python
from fastmcp import MCPClient
import requests

# Health
print(requests.get("http://localhost:7860/api/health").json())

# fastmcp tools (served under /mcp)
client = MCPClient("http://localhost:7860/mcp")

# Initialize
init = client.call("initialize_meta_analysis", name="Demo", study_type="clinical_trial", effect_measure="OR", analysis_model="random")
print(init)
session_id = init.get("result", {}).get("content", [{}])[0].get("text", "")

# Upload (base64 content expected)
import base64
csv = "study_id,effect_size,se\nS1,0.2,0.1\nS2,0.1,0.12\nS3,0.3,0.15\n"
enc = base64.b64encode(csv.encode()).decode()
print(client.call("upload_study_data", session_id=session_id, data_format="csv", data_content=enc, validation_level="basic"))

# Analysis
print(client.call("perform_meta_analysis", session_id=session_id, heterogeneity_test=True, publication_bias=True, sensitivity_analysis=False))

# Forest plot
print(client.call("generate_forest_plot", session_id=session_id, plot_style="classic", confidence_level=0.95))
```
