from __future__ import annotations

import asyncio
import json
from pathlib import Path

import typer

from omniterm.approvals import CommandApprovalPolicy
from omniterm.models import Message
from omniterm.providers.ollama import OllamaProvider
from omniterm.tools import CommandApprovalRequired, FilesystemTools, TerminalTool
from omniterm.workspace import Workspace

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

    _run_async(run())


@app.command("files")
def files_command(
    workspace: Path = typer.Option(Path.cwd(), exists=True, file_okay=False),
    path: str = typer.Argument("."),
) -> None:
    """List files within a selected workspace."""
    tools = FilesystemTools(Workspace.from_path(workspace))
    typer.echo(json.dumps(tools.list_directory(path), indent=2))


@app.command("run")
def run_command(
    command: str = typer.Argument(..., help="Shell command to execute"),
    workspace: Path = typer.Option(Path.cwd(), exists=True, file_okay=False),
    approve: bool = typer.Option(False, "--approve", help="Approve an ASK-level command"),
    timeout: float = typer.Option(60.0, min=0.1, help="Command timeout in seconds"),
) -> None:
    """Run a command inside the workspace using the approval policy."""

    async def run() -> None:
        terminal = TerminalTool(
            workspace=Workspace.from_path(workspace),
            policy=CommandApprovalPolicy(),
            timeout_seconds=timeout,
        )
        result = await terminal.run(command, approved=approve)
        if result.stdout:
            typer.echo(result.stdout, nl=not result.stdout.endswith("\n"))
        if result.stderr:
            typer.echo(result.stderr, err=True, nl=not result.stderr.endswith("\n"))
        if result.timed_out:
            typer.secho("Command timed out", fg=typer.colors.YELLOW, err=True)
        if result.returncode:
            raise typer.Exit(result.returncode)

    try:
        asyncio.run(run())
    except CommandApprovalRequired as exc:
        typer.secho(
            f"Approval required: {exc.command}\nReason: {exc.approval.reason}\n"
            "Run again with --approve after reviewing the command.",
            fg=typer.colors.YELLOW,
            err=True,
        )
        raise typer.Exit(code=2) from exc
    except PermissionError as exc:
        typer.secho(f"Command denied: {exc}", fg=typer.colors.RED, err=True)
        raise typer.Exit(code=3) from exc
    except Exception as exc:
        typer.secho(f"OmniTerm error: {exc}", fg=typer.colors.RED, err=True)
        raise typer.Exit(code=1) from exc


def _run_async(coroutine: object) -> None:
    try:
        asyncio.run(coroutine)
    except Exception as exc:
        typer.secho(f"OmniTerm error: {exc}", fg=typer.colors.RED, err=True)
        raise typer.Exit(code=1) from exc


if __name__ == "__main__":
    app()
