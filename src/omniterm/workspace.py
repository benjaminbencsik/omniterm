from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


class WorkspaceViolation(ValueError):
    """Raised when a tool attempts to access a path outside the workspace."""


@dataclass(frozen=True, slots=True)
class Workspace:
    root: Path

    @classmethod
    def from_path(cls, path: str | Path) -> "Workspace":
        root = Path(path).expanduser().resolve(strict=True)
        if not root.is_dir():
            raise ValueError(f"Workspace is not a directory: {root}")
        return cls(root=root)

    def resolve(self, path: str | Path = ".", *, must_exist: bool = False) -> Path:
        candidate = Path(path).expanduser()
        if not candidate.is_absolute():
            candidate = self.root / candidate
        candidate = candidate.resolve(strict=must_exist)

        try:
            candidate.relative_to(self.root)
        except ValueError as exc:
            raise WorkspaceViolation(
                f"Path escapes the selected workspace: {candidate}"
            ) from exc

        return candidate
