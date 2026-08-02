#!/usr/bin/env bash
set -euo pipefail

# End-to-end тест запускается без Bats: достаточно Git Bash, Git и development
# venv. Все Git-операции происходят в отдельном временном репозитории.
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/custodes-cli-test.XXXXXX")"

cleanup() {
    local allowed_prefix="${TMPDIR:-/tmp}/custodes-cli-test."
    if [[ "$TEST_ROOT" == "${allowed_prefix}"* ]]; then
        rm -rf -- "$TEST_ROOT"
    fi
}
trap cleanup EXIT

export CUSTODES_HOME="${TEST_ROOT}/home"
mkdir -p "$CUSTODES_HOME"
cp "${PROJECT_ROOT}/config/custodes.env.example" "${CUSTODES_HOME}/.env"

REPOSITORY="${TEST_ROOT}/repository"
mkdir -p "$REPOSITORY"
git -C "$REPOSITORY" init -q
git -C "$REPOSITORY" config user.name "Custodes CLI Test"
git -C "$REPOSITORY" config user.email "test@example.invalid"
printf 'base\n' > "${REPOSITORY}/sample.txt"
git -C "$REPOSITORY" add sample.txt
git -C "$REPOSITORY" -c core.hooksPath=/dev/null commit -qm base

cd "$REPOSITORY"
"${PROJECT_ROOT}/custodes.sh" init >/dev/null
grep -Fq '# Managed by Custodes' .git/hooks/pre-commit

printf 'safe change\n' >> sample.txt
git add sample.txt
git commit -qm safe >/dev/null

printf 'API_KEY=demo-value\n' > banword.txt
git add banword.txt
if git commit -qm banword-fixture >/dev/null 2>&1; then
    printf 'Expected banword finding to block the commit.\n' >&2
    exit 1
fi
git rm --cached -q banword.txt
rm -f -- banword.txt

printf 'credential=aB3dE5fG7hJ9kL2mN4pQ6rS8tV0xYz1C\n' > entropy.txt
git add entropy.txt
if git commit -qm entropy-fixture >/dev/null 2>&1; then
    printf 'Expected entropy finding to block the commit.\n' >&2
    exit 1
fi

"${PROJECT_ROOT}/custodes.sh" remove >/dev/null
[[ ! -e .git/hooks/pre-commit ]]
printf 'Custodes CLI integration test: OK\n'
