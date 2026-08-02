"""Правила сканирования и безопасное представление найденных нарушений."""

from __future__ import annotations

import re
from dataclasses import dataclass
from fnmatch import fnmatchcase
from pathlib import Path

from .config import Settings
from .entropy import entropy_candidates, shannon_entropy
from .git_diff import repository_root, staged_added_lines

ASSIGNMENT_RE = re.compile(r"(?P<prefix>\b[A-Za-z_][\w.-]*\s*[:=]\s*)(?P<value>.+)")


@dataclass(frozen=True)
class Finding:
    path: str
    line_number: int
    kind: str
    rule: str
    preview: str
    entropy: float | None = None


def safe_preview(line: str, reveal_values: bool) -> str:
    """По умолчанию не дублирует возможный секрет в терминал/CI-лог."""
    compact = line.strip().replace("\t", " ")
    if reveal_values:
        return compact[:160]
    match = ASSIGNMENT_RE.search(compact)
    if match:
        return f"{match.group('prefix')}<redacted>"
    return "<redacted>"


def repository_ignore_patterns(root: Path) -> tuple[str, ...]:
    """Читает простые glob-паттерны из versioned .custodesignore."""
    ignore_file = root / ".custodesignore"
    if not ignore_file.is_file():
        return ()
    patterns: list[str] = []
    for line in ignore_file.read_text(encoding="utf-8").splitlines():
        pattern = line.strip()
        if pattern and not pattern.startswith("#"):
            patterns.append(pattern.replace("\\", "/"))
    return tuple(patterns)


def path_is_excluded(path: str, patterns: tuple[str, ...]) -> bool:
    normalized = path.replace("\\", "/")
    return any(fnmatchcase(normalized, pattern) for pattern in patterns)


def _add_banword_findings(
    findings: list[Finding],
    seen: set[tuple[str, int, str, str]],
    settings: Settings,
    path: str,
    line_number: int,
    text: str,
) -> None:
    """Добавляет совпадения banwords и не дублирует одинаковые правила."""
    lowered = text.lower()
    for banword in settings.banwords:
        normalized_rule = banword.lower()
        key = (path, line_number, "banword", normalized_rule)
        if normalized_rule not in lowered or key in seen:
            continue
        seen.add(key)
        findings.append(
            Finding(
                path=path,
                line_number=line_number,
                kind="banword",
                rule=banword,
                preview=safe_preview(text, settings.reveal_values),
            )
        )


def _add_entropy_findings(
    findings: list[Finding],
    seen: set[tuple[str, int, str, str]],
    settings: Settings,
    path: str,
    line_number: int,
    text: str,
) -> None:
    """Добавляет высокоэнтропийные токены, если проверка включена."""
    if not settings.entropy_enabled:
        return
    for candidate in entropy_candidates(text, settings.entropy_min_length):
        entropy = shannon_entropy(candidate)
        key = (path, line_number, "entropy", candidate)
        if entropy < settings.entropy_threshold or key in seen:
            continue
        seen.add(key)
        findings.append(
            Finding(
                path=path,
                line_number=line_number,
                kind="entropy",
                rule=f">={settings.entropy_threshold:.2f}",
                preview=safe_preview(text, settings.reveal_values),
                entropy=entropy,
            )
        )


def scan_staged(settings: Settings, repo: Path | None = None) -> list[Finding]:
    findings: list[Finding] = []
    seen: set[tuple[str, int, str, str]] = set()
    root = repository_root(repo)
    excluded_paths = settings.excluded_paths + repository_ignore_patterns(root)

    for added in staged_added_lines(root):
        if path_is_excluded(added.path, excluded_paths):
            continue
        arguments = (
            findings,
            seen,
            settings,
            added.path,
            added.line_number,
            added.text,
        )
        _add_banword_findings(*arguments)
        _add_entropy_findings(*arguments)
    return findings
