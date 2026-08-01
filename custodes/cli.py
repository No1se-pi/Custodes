"""Консольный вход Python-сканера. Оркестрация CLI остаётся в Bash."""

from __future__ import annotations

import os
import sys
import traceback
from pathlib import Path

from .config import load_settings
from .git_diff import GitDiffError
from .scanner import Finding, scan_staged

LOGO = r"""
   |\                 /|
   | \               / |
   |* \     /\      / *|
   |  /    /  \     \  |
   | /    / /\ \     \ |
   |/    / /()\ \     \|
   |\   / /____\ \    /|
   | \ /________\ \  / |
   |  /___________ \   |
"""


def _paint(text: str, code: str) -> str:
    if not sys.stdout.isatty() or os.getenv("NO_COLOR"):
        return text
    return f"\033[{code}m{text}\033[0m"


def _finding_text(finding: Finding, language: str) -> str:
    if finding.kind == "entropy":
        reason = (
            f"высокая энтропия {finding.entropy:.2f} {finding.rule}"
            if language == "ru"
            else f"high entropy {finding.entropy:.2f} {finding.rule}"
        )
    else:
        reason = (
            f"стоп-слово: {finding.rule}"
            if language == "ru"
            else f"banword: {finding.rule}"
        )
    return f"  {finding.path}:{finding.line_number}  {reason}\n    {finding.preview}"


def main() -> int:
    settings = load_settings()
    try:
        findings = scan_staged(settings, Path.cwd())
    except GitDiffError as error:
        label = "Ошибка Git" if settings.language == "ru" else "Git error"
        print(_paint(f"[!] {label}: {error}", "31"), file=sys.stderr)
        return 2
    except Exception as error:  # noqa: BLE001 - CLI должен вернуть infrastructure code.
        label = "Ошибка scanner" if settings.language == "ru" else "Scanner error"
        print(_paint(f"[!] {label}: {error}", "31"), file=sys.stderr)
        if os.getenv("CUSTODES_DEBUG"):
            traceback.print_exc()
        return 2

    if not findings:
        message = (
            "Staged-изменения прошли проверку секретов."
            if settings.language == "ru"
            else "Staged changes passed the secret scan."
        )
        print(_paint(f"[OK] {message}", "32"))
        return 0

    if settings.show_logo:
        print(_paint(LOGO, "35"))
    title = (
        f"Коммит заблокирован: найдено нарушений — {len(findings)}."
        if settings.language == "ru"
        else f"Commit blocked: {len(findings)} finding(s)."
    )
    print(_paint(f"[BLOCK] {title}", "31"))
    if settings.output_violations:
        for finding in findings:
            print(_finding_text(finding, settings.language))
    hint = (
        f"Настройки: {settings.config_path}"
        if settings.language == "ru"
        else f"Settings: {settings.config_path}"
    )
    print(_paint(hint, "90"))
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
