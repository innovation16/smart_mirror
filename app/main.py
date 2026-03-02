from fastapi import FastAPI, HTTPException

from app.agent import agent
from app.schemas import ChatRequest, ChatResponse

app = FastAPI(title="smart-mirror-agent", version="0.1.0")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/chat", response_model=ChatResponse)
def chat(payload: ChatRequest) -> ChatResponse:
    try:
        answer = agent.chat(prompt=payload.prompt, thread_id=payload.thread_id)
    except Exception as exc:  # pragma: no cover
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    return ChatResponse(response=answer, thread_id=payload.thread_id)
