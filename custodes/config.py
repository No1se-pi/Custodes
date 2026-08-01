"""Загрузка настроек Custodes без чтения .env проверяемого проекта."""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import dotenv_values

DEFAULT_BANWORDS = (
    "api_key",
    "apikey",
    "password",
    "private_key",
    "secret_key",
    "access_token",
)


def _first(values: dict[str, str | None], *names: str, default: str = "") -> str:
    """Возвращает первое непустое значение с поддержкой старых имён ключей."""
    for name in names:
        value = os.getenv(name)
        if value is None:
            value = values.get(name)
        if value is not None and str(value).strip():
            return str(value).strip()
    return default


def _as_bool(value: str, default: bool = False) -> bool:
    if not value:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on", "y"}


@dataclass(frozen=True)
class Settings:
    """Неизменяемые настройки одного запуска сканера."""

    config_path: Path
    language: str
    banwords: tuple[str, ...]
    excluded_paths: tuple[str, ...]
    entropy_enabled: bool
    entropy_threshold: float
    entropy_min_length: int
    output_violations: bool
    reveal_values: bool
    show_logo: bool


def default_config_path() -> Path:
    override = os.getenv("CUSTODES_CONFIG")
    if override:
        return Path(override).expanduser()
    return Path.home() / ".local" / "share" / "custodes" / ".env"


def load_settings(config_path: Path | None = None) -> Settings:
    """Загружает только конфиг Custodes, а не .env проверяемого проекта."""
    path = (config_path or default_config_path()).expanduser()
    values = dict(dotenv_values(path)) if path.is_file() else {}

    raw_banwords = _first(
        values,
        "CUSTODES_BANWORDS",
        "banwords",
        default=",".join(DEFAULT_BANWORDS),
    )
    banwords = tuple(
        dict.fromkeys(word.strip() for word in raw_banwords.split(",") if word.strip())
    )
    raw_excluded_paths = _first(
        values,
        "CUSTODES_EXCLUDE_PATHS",
        default="venv/**,.venv/**,node_modules/**",
    )
    excluded_paths = tuple(
        dict.fromkeys(
            pattern.strip().replace("\\", "/")
            for pattern in raw_excluded_paths.split(",")
            if pattern.strip()
        )
    )

    language = _first(values, "CUSTODES_LANG", "lang_custodes", default="eng").lower()
    if language not in {"eng", "ru"}:
        language = "eng"

    try:
        threshold = float(_first(values, "CUSTODES_ENTROPY_THRESHOLD", default="4.0"))
    except ValueError:
        threshold = 4.0
    try:
        min_length = int(_first(values, "CUSTODES_ENTROPY_MIN_LENGTH", default="20"))
    except ValueError:
        min_length = 20

    # Границы защищают от случайной настройки, блокирующей буквально всё.
    threshold = min(max(threshold, 2.5), 8.0)
    min_length = min(max(min_length, 12), 512)

    return Settings(
        config_path=path,
        language=language,
        banwords=banwords,
        excluded_paths=excluded_paths,
        entropy_enabled=_as_bool(
            _first(values, "CUSTODES_ENTROPY_ENABLED", "entropy", default="yes")
        ),
        entropy_threshold=threshold,
        entropy_min_length=min_length,
        output_violations=_as_bool(
            _first(
                values,
                "CUSTODES_OUTPUT_VIOLATIONS",
                "output_violations",
                default="yes",
            )
        ),
        reveal_values=_as_bool(_first(values, "CUSTODES_REVEAL_VALUES", default="no")),
        show_logo=_as_bool(
            _first(values, "CUSTODES_LOGO", "logo_custodes", default="yes")
        ),
    )
