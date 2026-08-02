"""Эвристика поиска похожих на секреты высокоэнтропийных токенов."""

from __future__ import annotations

import re
from collections import Counter
from math import log2

# Знак ``=`` разделяет имя и значение настройки. Padding base64 на конце
# безопасно отбрасывается, поэтому включать его в кандидат не нужно.
# ``re.ASCII`` сохраняет прежнюю семантику диапазона A-Z/a-z/0-9, но делает
# выражение короче и понятнее для статического анализатора.
TOKEN_RE = re.compile(r"[\w+./-]+", flags=re.ASCII)
PLACEHOLDER_MARKERS = (
    "changeme",
    "change_me",
    "example",
    "placeholder",
    "dummy",
    "sample",
    "your_token",
    "xxxxxxxx",
)
PATH_SUFFIXES = (
    ".css",
    ".git",
    ".html",
    ".js",
    ".json",
    ".md",
    ".py",
    ".sh",
    ".svg",
    ".toml",
    ".ts",
    ".yaml",
    ".yml",
)


def shannon_entropy(value: str | bytes) -> float:
    """Возвращает энтропию Шеннона в битах на символ/байт."""
    if not value:
        return 0.0
    counts = Counter(value)
    length = len(value)
    return -sum((count / length) * log2(count / length) for count in counts.values())


def _looks_like_placeholder(candidate: str) -> bool:
    lowered = candidate.lower()
    return any(marker in lowered for marker in PLACEHOLDER_MARKERS)


def _has_secret_like_diversity(candidate: str) -> bool:
    """Отсекает длинные слова и монотонные строки."""
    categories = sum(
        (
            any(char.islower() for char in candidate),
            any(char.isupper() for char in candidate),
            any(char.isdigit() for char in candidate),
            any(not char.isalnum() for char in candidate),
        )
    )
    return categories >= 2 and len(set(candidate)) >= 8


def _looks_like_code_url_or_path(candidate: str) -> bool:
    """Отсекает структурный текст, который часто имеет entropy около 4."""
    lowered = candidate.lower()
    if candidate.startswith("//") or ".com/" in lowered or ".io/" in lowered:
        return True
    if "/" in candidate and (
        candidate.count("/") >= 2 or lowered.endswith(PATH_SUFFIXES)
    ):
        return True
    # Python/JS member expression: ASSIGNMENT_RE.search или client.auth.login.
    return bool(
        "." in candidate
        and re.fullmatch(r"[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)+", candidate, re.ASCII)
    )


def entropy_candidates(line: str, min_length: int) -> list[str]:
    """Извлекает уникальные токены-кандидаты из добавленной строки."""
    candidates: list[str] = []
    seen: set[str] = set()
    for match in TOKEN_RE.finditer(line):
        candidate = match.group(0).strip("._-/=")
        if (
            len(candidate) < min_length
            or candidate in seen
            or _looks_like_placeholder(candidate)
            or _looks_like_code_url_or_path(candidate)
            or not _has_secret_like_diversity(candidate)
        ):
            continue
        seen.add(candidate)
        candidates.append(candidate)
    return candidates
