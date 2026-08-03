from pathlib import Path

import pytest

from omniterm.tools.filesystem import FilesystemTools
from omniterm.workspace import Workspace, WorkspaceViolation


def test_write_read_and_list_file(tmp_path: Path) -> None:
    tools = FilesystemTools(Workspace.from_path(tmp_path))

    result = tools.write_file("src/example.txt", "hello")

    assert result["path"] == "src/example.txt"
    assert tools.read_file("src/example.txt") == "hello"
    assert tools.list_directory("src")[0]["name"] == "example.txt"


def test_write_refuses_overwrite_by_default(tmp_path: Path) -> None:
    tools = FilesystemTools(Workspace.from_path(tmp_path))
    tools.write_file("example.txt", "first")

    with pytest.raises(FileExistsError):
        tools.write_file("example.txt", "second")


def test_file_tools_cannot_escape_workspace(tmp_path: Path) -> None:
    tools = FilesystemTools(Workspace.from_path(tmp_path))

    with pytest.raises(WorkspaceViolation):
        tools.read_file("../outside.txt")
