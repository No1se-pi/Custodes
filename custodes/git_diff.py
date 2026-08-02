"""Чтение только добавленных строк из Git index (staged diff)."""

from __future__ import annotations

import re
import subprocess
from dataclasses import dataclass
from pathlib import Path

HUNK_RE = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@")


class GitDiffError(RuntimeError):
    """Git не смог вернуть staged diff."""


@dataclass(frozen=True)
class AddedLine:
    path: str
    line_number: int
    text: str


def _git(repo: Path, *args: str) -> bytes:
    process = subprocess.run(
        ["git", *args],
        cwd=repo,
        capture_output=True,
        check=False,
    )
    if process.returncode != 0:
        message = process.stderr.decode("utf-8", errors="replace").strip()
        raise GitDiffError(message or "git command failed")
    return process.stdout


def repository_root(path: Path | None = None) -> Path:
    repo = (path or Path.cwd()).resolve()
    output = _git(repo, "rev-parse", "--show-toplevel")
    return Path(output.decode("utf-8", errors="surrogateescape").strip())


def staged_files(repo: Path) -> list[str]:
    """NUL-разделитель сохраняет пробелы и спецсимволы в именах файлов."""
    output = _git(
        repo,
        "diff",
        "--cached",
        "--name-only",
        "--diff-filter=ACMR",
        "-z",
        "--",
    )
    return [
        item.decode("utf-8", errors="surrogateescape")
        for item in output.split(b"\0")
        if item
    ]


def added_lines_for_file(repo: Path, path: str) -> list[AddedLine]:
    patch = _git(
        repo,
        "diff",
        "--cached",
        "--no-color",
        "--no-ext-diff",
        "--no-textconv",
        "--unified=0",
        "--",
        path,
    ).decode("utf-8", errors="replace")

    result: list[AddedLine] = []
    new_line = 0
    inside_hunk = False
    for raw_line in patch.splitlines():
        hunk = HUNK_RE.match(raw_line)
        if hunk:
            new_line = int(hunk.group(1))
            inside_hunk = True
            continue
        if not inside_hunk:
            continue
        if raw_line.startswith("+"):
            result.append(AddedLine(path, new_line, raw_line[1:]))
            new_line += 1
        elif raw_line.startswith(("-", "\\ No newline")):
            continue
        else:
            new_line += 1
    return result


def staged_added_lines(repo: Path | None = None) -> list[AddedLine]:
    root = repository_root(repo)
    lines: list[AddedLine] = []
    for path in staged_files(root):
        lines.extend(added_lines_for_file(root, path))
    return lines
