from fastapi import FastAPI, Body
from fastapi.responses import JSONResponse
import gradio as gr

from app import build_ui, call_tool, R_STATUS, PY_STATUS

app = FastAPI(title="MCP Meta-Analysis PoC API")

demo = build_ui()
app = gr.mount_gradio_app(app, demo, path="/")


@app.get("/api/health")
def health():
    return {"r_status": R_STATUS, "python_status": PY_STATUS}


@app.post("/api/{tool}")
def call_tool_endpoint(tool: str, payload: dict = Body(...)):
    try:
        result = call_tool(tool, payload)
        return JSONResponse(content={"status": "ok", "result": result})
    except Exception as e:
        return JSONResponse(status_code=500, content={"status": "error", "message": str(e)})
