from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field


Role = Literal["system", "user", "assistant", "tool"]


class Message(BaseModel):
    role: Role
    content: str
    name: str | None = None
    tool_call_id: str | None = None


class ToolCall(BaseModel):
    id: str
    name: str
    arguments: dict[str, Any] = Field(default_factory=dict)


class ModelResponse(BaseModel):
    text: str = ""
    tool_calls: list[ToolCall] = Field(default_factory=list)
    usage: dict[str, int] | None = None


class ToolResult(BaseModel):
    tool_call_id: str
    name: str
    output: str
    is_error: bool = False

    def as_message(self) -> Message:
        return Message(
            role="tool",
            name=self.name,
            tool_call_id=self.tool_call_id,
            content=self.output,
        )
