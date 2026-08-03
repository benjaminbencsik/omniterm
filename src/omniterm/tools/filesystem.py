from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from omniterm.workspace import Workspace


@dataclass(slots=True)
class FilesystemTools:
    workspace: Workspace
    max_read_bytes: int = 1_000_000

    def list_directory(self, path: str = ".") -> list[dict[str, object]]:
        directory = self.workspace.resolve(path, must_exist=True)
        if not directory.is_dir():
            raise NotADirectoryError(directory)

        entries: list[dict[str, object]] = []
        for item in sorted(directory.iterdir(), key=lambda value: (not value.is_dir(), value.name.lower())):
            stat = item.stat()
            entries.append(
                {
                    "name": item.name,
                    "path": item.relative_to(self.workspace.root).as_posix(),
                    "type": "directory" if item.is_dir() else "file",
                    "size": stat.st_size,
                }
            )
        return entries

    def read_file(self, path: str) -> str:
        target = self.workspace.resolve(path, must_exist=True)
        if not target.is_file():
            raise IsADirectoryError(target)
        if target.stat().st_size > self.max_read_bytes:
            raise ValueError(
                f"File exceeds the {self.max_read_bytes}-byte read limit: {target.name}"
            )
        return target.read_text(encoding="utf-8")

    def write_file(self, path: str, content: str, *, overwrite: bool = False) -> dict[str, object]:
        target = self.workspace.resolve(path)
        if target.exists() and not overwrite:
            raise FileExistsError(f"Refusing to overwrite existing file: {target}")

        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
        return {
            "path": target.relative_to(self.workspace.root).as_posix(),
            "bytes_written": len(content.encode("utf-8")),
        }

    def search_files(self, query: str, path: str = ".", *, limit: int = 100) -> list[str]:
        root = self.workspace.resolve(path, must_exist=True)
        if not root.is_dir():
            raise NotADirectoryError(root)

        lowered = query.lower()
        matches: list[str] = []
        for item in root.rglob("*"):
            if len(matches) >= limit:
                break
            if item.is_file() and lowered in item.name.lower():
                matches.append(item.relative_to(self.workspace.root).as_posix())
        return matches
