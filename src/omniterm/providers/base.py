from __future__ import annotations

from abc import ABC, abstractmethod
from collections.abc import Sequence

from omniterm.models import Message, ModelResponse


class ModelProvider(ABC):
    """Provider-neutral interface used by the agent loop."""

    @abstractmethod
    async def complete(
        self,
        messages: Sequence[Message],
        *,
        model: str,
        tools: list[dict] | None = None,
    ) -> ModelResponse:
        raise NotImplementedError
