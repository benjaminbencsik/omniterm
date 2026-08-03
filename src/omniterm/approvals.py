from __future__ import annotations

import re
import shlex
from dataclasses import dataclass
from enum import StrEnum


class ApprovalDecision(StrEnum):
    ALLOW = "allow"
    ASK = "ask"
    DENY = "deny"


@dataclass(frozen=True, slots=True)
class ApprovalResult:
    decision: ApprovalDecision
    reason: str


class CommandApprovalPolicy:
    """Conservative command policy for the first OmniTerm runtime."""

    _DENY_PATTERNS = (
        r"(^|\s)(sudo|su|doas)(\s|$)",
        r"(^|\s)(shutdown|reboot|poweroff|halt)(\s|$)",
        r"(^|\s)(mkfs|fdisk|parted)(\s|$)",
        r"rm\s+-[^\n]*r[^\n]*f[^\n]*(/|~|\*)",
        r"del\s+/[fsq].*\\",
        r"format\s+[a-z]:",
        r"reg\s+(delete|add)",
    )

    _ASK_COMMANDS = {
        "curl",
        "wget",
        "git",
        "npm",
        "pnpm",
        "yarn",
        "pip",
        "pip3",
        "uv",
        "cargo",
        "docker",
        "podman",
        "powershell",
        "pwsh",
        "cmd",
        "bash",
        "sh",
    }

    _ALLOW_COMMANDS = {
        "cat",
        "dir",
        "echo",
        "find",
        "git",
        "grep",
        "head",
        "ls",
        "pwd",
        "python",
        "python3",
        "rg",
        "tail",
        "type",
        "where",
        "which",
    }

    def evaluate(self, command: str) -> ApprovalResult:
        normalized = command.strip()
        if not normalized:
            return ApprovalResult(ApprovalDecision.DENY, "Empty command")

        lowered = normalized.lower()
        for pattern in self._DENY_PATTERNS:
            if re.search(pattern, lowered, flags=re.IGNORECASE):
                return ApprovalResult(
                    ApprovalDecision.DENY,
                    "Command matches a blocked destructive or privileged pattern",
                )

        executable = self._first_executable(normalized).lower()

        if executable == "git":
            if re.search(r"\bgit\s+(status|diff|log|show|branch)(\s|$)", lowered):
                return ApprovalResult(ApprovalDecision.ALLOW, "Read-only Git command")
            return ApprovalResult(ApprovalDecision.ASK, "Git command may change repository state")

        if executable in self._ASK_COMMANDS:
            return ApprovalResult(
                ApprovalDecision.ASK,
                "Command may access the network, install software, or start another shell",
            )

        if executable in self._ALLOW_COMMANDS:
            return ApprovalResult(ApprovalDecision.ALLOW, "Recognized low-risk command")

        return ApprovalResult(
            ApprovalDecision.ASK,
            "Unknown commands require explicit approval",
        )

    @staticmethod
    def _first_executable(command: str) -> str:
        try:
            parts = shlex.split(command, posix=False)
        except ValueError:
            return ""
        return parts[0].strip('"\'') if parts else ""
