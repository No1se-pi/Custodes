from __future__ import annotations

import io
import os
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from custodes import cli
from custodes.git_diff import GitDiffError
from custodes.scanner import Finding


def settings(language: str = "ru") -> SimpleNamespace:
    """Минимальные настройки для тестирования только слоя отображения CLI."""
    return SimpleNamespace(
        language=language,
        show_logo=True,
        output_violations=True,
        config_path=Path("custodes.env"),
    )


class CliTests(unittest.TestCase):
    def test_clean_scan_returns_success(self) -> None:
        output = io.StringIO()
        with (
            patch.object(cli, "load_settings", return_value=settings()),
            patch.object(cli, "scan_staged", return_value=[]),
            redirect_stdout(output),
        ):
            self.assertEqual(0, cli.main())
        self.assertIn("прошли проверку", output.getvalue())

    def test_findings_are_redacted_and_block_commit(self) -> None:
        findings = [
            Finding("config.py", 2, "banword", "password", "password=<redacted>"),
            Finding("token.txt", 1, "entropy", ">=4.00", "<redacted>", 4.75),
        ]
        output = io.StringIO()
        with (
            patch.object(cli, "load_settings", return_value=settings("en")),
            patch.object(cli, "scan_staged", return_value=findings),
            redirect_stdout(output),
        ):
            self.assertEqual(1, cli.main())
        rendered = output.getvalue()
        self.assertIn("Commit blocked: 2", rendered)
        self.assertIn("banword: password", rendered)
        self.assertIn("high entropy 4.75", rendered)

    def test_git_failure_returns_infrastructure_code(self) -> None:
        errors = io.StringIO()
        with (
            patch.object(cli, "load_settings", return_value=settings("en")),
            patch.object(cli, "scan_staged", side_effect=GitDiffError("not a repo")),
            redirect_stderr(errors),
        ):
            self.assertEqual(2, cli.main())
        self.assertIn("Git error: not a repo", errors.getvalue())

    def test_unexpected_failure_supports_debug_traceback(self) -> None:
        errors = io.StringIO()
        with (
            patch.object(cli, "load_settings", return_value=settings()),
            patch.object(cli, "scan_staged", side_effect=RuntimeError("boom")),
            patch.dict(os.environ, {"CUSTODES_DEBUG": "1"}),
            redirect_stderr(errors),
        ):
            self.assertEqual(2, cli.main())
        self.assertIn("RuntimeError: boom", errors.getvalue())

    def test_paint_is_disabled_for_non_tty_output(self) -> None:
        self.assertEqual("plain", cli._paint("plain", "31"))


if __name__ == "__main__":
    unittest.main()
