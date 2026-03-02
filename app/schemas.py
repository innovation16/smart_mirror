from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    prompt: str = Field(..., min_length=1, description="User prompt sent to the agent")
    thread_id: str = Field(default="default", description="Conversation/thread identifier")


class ChatResponse(BaseModel):
    response: str
    thread_id: str
