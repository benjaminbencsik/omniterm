from pathlib import Path

import pytest

from omniterm.workspace import Workspace, WorkspaceViolation


def test_resolve_keeps_paths_inside_workspace(tmp_path: Path) -> None:
    workspace = Workspace.from_path(tmp_path)
    target = workspace.resolve("src/example.py")

    assert target == tmp_path / "src" / "example.py"


def test_resolve_rejects_parent_escape(tmp_path: Path) -> None:
    workspace = Workspace.from_path(tmp_path)

    with pytest.raises(WorkspaceViolation):
        workspace.resolve("../outside.txt")


def test_resolve_rejects_absolute_escape(tmp_path: Path) -> None:
    workspace = Workspace.from_path(tmp_path)
    outside = tmp_path.parent / "outside.txt"

    with pytest.raises(WorkspaceViolation):
        workspace.resolve(outside)
