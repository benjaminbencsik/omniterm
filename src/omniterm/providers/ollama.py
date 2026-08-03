from __future__ import annotations

import json
from collections.abc import Sequence

import httpx

from omniterm.models import Message, ModelResponse, ToolCall
from omniterm.providers.base import ModelProvider


class OllamaProvider(ModelProvider):
    def __init__(self, base_url: str = "http://127.0.0.1:11434") -> None:
        self.base_url = base_url.rstrip("/")

    async def complete(
        self,
        messages: Sequence[Message],
        *,
        model: str,
        tools: list[dict] | None = None,
    ) -> ModelResponse:
        payload: dict = {
            "model": model,
            "messages": [message.model_dump(exclude_none=True) for message in messages],
            "stream": False,
        }
        if tools:
            payload["tools"] = tools

        async with httpx.AsyncClient(timeout=120) as client:
            response = await client.post(f"{self.base_url}/api/chat", json=payload)
            response.raise_for_status()
            data = response.json()

        message = data.get("message", {})
        calls: list[ToolCall] = []
        for index, call in enumerate(message.get("tool_calls", [])):
            function = call.get("function", {})
            arguments = function.get("arguments", {})
            if isinstance(arguments, str):
                arguments = json.loads(arguments)
            calls.append(
                ToolCall(
                    id=call.get("id", f"ollama-{index}"),
                    name=function.get("name", ""),
                    arguments=arguments,
                )
            )

        return ModelResponse(text=message.get("content", ""), tool_calls=calls)
