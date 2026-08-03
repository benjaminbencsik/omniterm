from __future__ import annotations

import asyncio

import typer

from omniterm.models import Message
from omniterm.providers.ollama import OllamaProvider

app = typer.Typer(help="OmniTerm local-first coding agent")


@app.command()
def chat(
    prompt: str = typer.Argument(..., help="Prompt to send to the model"),
    model: str = typer.Option("qwen2.5-coder:7b", help="Ollama model name"),
    base_url: str = typer.Option("http://127.0.0.1:11434", help="Ollama base URL"),
) -> None:
    """Send one prompt to a local Ollama model."""

    async def run() -> None:
        provider = OllamaProvider(base_url=base_url)
        response = await provider.complete(
            [Message(role="user", content=prompt)],
            model=model,
        )
        typer.echo(response.text)

    try:
        asyncio.run(run())
    except Exception as exc:
        typer.secho(f"OmniTerm error: {exc}", fg=typer.colors.RED, err=True)
        raise typer.Exit(code=1) from exc


if __name__ == "__main__":
    app()
