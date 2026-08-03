from __future__ import annotations

import asyncio
from dataclasses import dataclass

from omniterm.approvals import ApprovalDecision, ApprovalResult, CommandApprovalPolicy
from omniterm.workspace import Workspace


class CommandApprovalRequired(PermissionError):
    def __init__(self, command: str, approval: ApprovalResult) -> None:
        super().__init__(approval.reason)
        self.command = command
        self.approval = approval


@dataclass(frozen=True, slots=True)
class CommandResult:
    command: str
    returncode: int
    stdout: str
    stderr: str
    timed_out: bool = False


@dataclass(slots=True)
class TerminalTool:
    workspace: Workspace
    policy: CommandApprovalPolicy
    timeout_seconds: float = 60.0
    max_output_chars: int = 100_000

    async def run(self, command: str, *, approved: bool = False) -> CommandResult:
        approval = self.policy.evaluate(command)
        if approval.decision is ApprovalDecision.DENY:
            raise PermissionError(approval.reason)
        if approval.decision is ApprovalDecision.ASK and not approved:
            raise CommandApprovalRequired(command, approval)

        process = await asyncio.create_subprocess_shell(
            command,
            cwd=self.workspace.root,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )

        try:
            stdout, stderr = await asyncio.wait_for(
                process.communicate(), timeout=self.timeout_seconds
            )
            timed_out = False
        except TimeoutError:
            process.kill()
            stdout, stderr = await process.communicate()
            timed_out = True

        return CommandResult(
            command=command,
            returncode=process.returncode if process.returncode is not None else -1,
            stdout=self._decode(stdout),
            stderr=self._decode(stderr),
            timed_out=timed_out,
        )

    def _decode(self, value: bytes) -> str:
        text = value.decode("utf-8", errors="replace")
        if len(text) <= self.max_output_chars:
            return text
        omitted = len(text) - self.max_output_chars
        return f"{text[: self.max_output_chars]}\n...[truncated {omitted} characters]"
