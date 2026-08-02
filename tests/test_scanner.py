from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path

from custodes.config import load_settings
from custodes.entropy import entropy_candidates, shannon_entropy
from custodes.scanner import scan_staged


def git(repo: Path, *args: str) -> None:
    subprocess.run(["git", *args], cwd=repo, check=True, capture_output=True)


class ScannerTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.repo = Path(self.temp.name)
        git(self.repo, "init", "-q")
        git(self.repo, "config", "user.name", "Custodes Test")
        git(self.repo, "config", "user.email", "test@example.invalid")
        (self.repo / "README.md").write_text("base\n", encoding="utf-8")
        git(self.repo, "add", "README.md")
        git(self.repo, "commit", "-qm", "base")

        self.config = self.repo / "custodes-test.env"
        self.config.write_text(
            "CUSTODES_BANWORDS=API_KEY,password\n"
            "CUSTODES_ENTROPY_ENABLED=yes\n"
            "CUSTODES_ENTROPY_THRESHOLD=4.0\n"
            "CUSTODES_ENTROPY_MIN_LENGTH=20\n"
            "CUSTODES_REVEAL_VALUES=no\n",
            encoding="utf-8",
        )

    def tearDown(self) -> None:
        self.temp.cleanup()

    def stage(self, name: str, content: str) -> None:
        (self.repo / name).write_text(content, encoding="utf-8")
        git(self.repo, "add", name)

    def test_banword_blocks_and_redacts_value(self) -> None:
        self.stage("settings.py", 'API_KEY="not-a-real-secret"\n')
        findings = scan_staged(load_settings(self.config), self.repo)
        self.assertTrue(any(item.kind == "banword" for item in findings))
        self.assertTrue(
            all("not-a-real-secret" not in item.preview for item in findings)
        )

    def test_entropy_alone_blocks_commit(self) -> None:
        synthetic = "aB3dE5fG7hJ9kL2mN4pQ6rS8tV0xYz1C"
        self.stage("config.txt", f"credential={synthetic}\n")
        findings = scan_staged(load_settings(self.config), self.repo)
        self.assertTrue(any(item.kind == "entropy" for item in findings))

    def test_low_entropy_placeholder_is_allowed(self) -> None:
        self.stage("example.txt", "credential=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n")
        findings = scan_staged(load_settings(self.config), self.repo)
        self.assertFalse(any(item.kind == "entropy" for item in findings))

    def test_deleted_secret_is_not_scanned(self) -> None:
        self.stage("old.txt", "API_KEY=temporary\n")
        git(self.repo, "commit", "-qm", "fixture")
        (self.repo / "old.txt").write_text("safe=true\n", encoding="utf-8")
        git(self.repo, "add", "old.txt")
        findings = scan_staged(load_settings(self.config), self.repo)
        self.assertFalse(any(item.kind == "banword" for item in findings))

    def test_filename_with_spaces_is_supported(self) -> None:
        self.stage("file with spaces.txt", "password=demo\n")
        findings = scan_staged(load_settings(self.config), self.repo)
        self.assertEqual("file with spaces.txt", findings[0].path)

    def test_repository_ignore_file_excludes_documented_fixture(self) -> None:
        (self.repo / ".custodesignore").write_text("fixtures/**\n", encoding="utf-8")
        (self.repo / "fixtures").mkdir()
        self.stage("fixtures/secret.txt", "API_KEY=synthetic\n")
        findings = scan_staged(load_settings(self.config), self.repo)
        self.assertEqual([], findings)

    def test_entropy_helpers(self) -> None:
        value = "aB3dE5fG7hJ9kL2mN4pQ6rS8tV0xYz1C"
        self.assertGreater(shannon_entropy(value), 4.0)
        self.assertEqual([value], entropy_candidates(f"token={value}", 20))

    def test_code_paths_and_urls_are_not_entropy_candidates(self) -> None:
        line = (
            "match = ASSIGNMENT_RE.search(compact); "
            'source "${ROOT}/lib/commands/repository.sh"; '
            'url="https://github.com/No1se-pi/Custodes.git"'
        )
        self.assertEqual([], entropy_candidates(line, 20))


if __name__ == "__main__":
    unittest.main()
