#!/usr/bin/env bash
# Dependency-free test suite for all skills and platform scripts.
# Usage: tests/run_tests.sh      Exit 0 = all pass.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SK="$ROOT/.bob/skills"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

PASS=0; FAILN=0
ok()   { PASS=$((PASS+1)); echo "  ok   $1"; }
bad()  { FAILN=$((FAILN+1)); echo "  FAIL $1"; }
# assert_rc <expected> <label> <cmd...>
assert_rc() { local e="$1" l="$2"; shift 2; "$@" >"$WORK/out" 2>&1; local rc=$?; [ "$rc" -eq "$e" ] && ok "$l" || { bad "$l (rc=$rc, want $e)"; sed 's/^/       /' "$WORK/out"; }; }
assert_file()    { [ -e "$2" ] && ok "$1" || bad "$1 (missing $2)"; }
assert_grep()    { grep -qE -- "$2" "$3" && ok "$1" || bad "$1 (no /$2/ in $3)"; }
assert_no_grep() { grep -qE -- "$2" "$3" && bad "$1 (unexpected /$2/ in $3)" || ok "$1"; }
new() { rm -rf "$WORK/p"; mkdir -p "$WORK/p"; echo "$WORK/p"; }

echo "== git-hygiene"
P="$(new)"; G="$SK/git-hygiene/scripts/ensure_gitignore.sh"
assert_rc 1 "check fails without .gitignore" bash "$G" --check "$P"
assert_rc 0 "creates .gitignore" bash "$G" "$P"
for e in '^\.env$' '^_\*/$' '^node_modules/$' '^\.playwright-mcp/$' '^\*\.onnx$' '^AGENTS\.md$' '^\.bob/mcp\.json$' '^input/\*$' '^output/\*$' '^\*\.dylib$'; do
  assert_grep "entry $e" "$e" "$P/.gitignore"
done
assert_file "input/.gitkeep" "$P/input/.gitkeep"
assert_file "output/.gitkeep" "$P/output/.gitkeep"
assert_rc 0 "check passes afterwards" bash "$G" --check "$P"
bash "$G" "$P" >/dev/null; N1="$(wc -l < "$P/.gitignore")"; bash "$G" "$P" >/dev/null
[ "$N1" = "$(wc -l < "$P/.gitignore")" ] && ok "idempotent (no duplicates)" || bad "idempotent"
P="$(new)"; printf 'custom-line' > "$P/.gitignore"; bash "$G" "$P" >/dev/null
assert_grep "keeps existing line" '^custom-line$' "$P/.gitignore"

echo "== secure-config"
P="$(new)"; S="$SK/secure-config/scripts/scan_secrets.sh"
echo 'x = 1' > "$P/ok.py"; touch "$P/.env.example"
assert_rc 0 "clean project passes" bash "$S" "$P"
echo 'api_key = "abcd1234efgh5678"' > "$P/bad.py"  # nosecret (test fixture)
assert_rc 1 "detects hard-coded api key" bash "$S" "$P"
echo 'api_key = "abcd1234efgh5678"  # nosecret' > "$P/bad.py"
assert_rc 0 "nosecret marker suppresses" bash "$S" "$P"
echo 'key = os.environ["API_KEY"]' > "$P/bad.py"
assert_rc 0 "env reference is fine" bash "$S" "$P"
echo 'contact = "john@corp.io"' > "$P/bad.py"  # nosecret (test fixture)
assert_rc 1 "detects hard-coded e-mail" bash "$S" "$P"
echo 'k = "AKIAABCDEFGHIJKLMNOP"' > "$P/bad.py"  # nosecret (test fixture)
assert_rc 1 "detects AWS key shape" bash "$S" "$P"
echo 'u = "http://localhost:9931/v1"' > "$P/bad.py"
assert_rc 0 "URL ignored without --strict" bash "$S" "$P"
assert_rc 1 "URL flagged with --strict" bash "$S" --strict "$P"
rm "$P/bad.py"; rm "$P/.env.example"
OUTW="$(bash "$S" "$P" 2>&1)"; echo "$OUTW" | grep -q 'no .env.example' && ok "warns on missing .env.example" || bad "missing .env.example warning"

echo "== project-lifecycle-scripts"
P="$(new)"; L="$SK/project-lifecycle-scripts/scripts/scaffold_scripts.sh"
assert_rc 0 "scaffold" bash "$L" --images "$P"
for f in start stop cleanup cleanup-images; do
  [ -x "$P/scripts/$f.sh" ] && ok "$f.sh executable" || bad "$f.sh executable"
done
assert_grep ".env.example has APP_START_CMD" '^APP_START_CMD=' "$P/.env.example"
assert_grep ".env.example has PROJECT_IMAGES" '^PROJECT_IMAGES=' "$P/.env.example"
echo '# custom' >> "$P/scripts/start.sh"; bash "$L" "$P" >/dev/null
assert_grep "existing script kept (no --force)" '^# custom$' "$P/scripts/start.sh"
bash "$L" --force "$P" >/dev/null
assert_no_grep "--force overwrites" '^# custom$' "$P/scripts/start.sh"
# Functional start/stop with a real detached process.
echo 'APP_START_CMD="sleep 300"' > "$P/.env"; echo 'APP_PORT=8765' >> "$P/.env"
assert_rc 0 "start.sh launches" "$P/scripts/start.sh"
assert_grep "start prints URL" '^URL: http://localhost:8765' "$WORK/out"
PID="$(cat "$P/.run/app.pid")"; kill -0 "$PID" 2>/dev/null && ok "process alive" || bad "process alive"
assert_rc 0 "second start is idempotent" "$P/scripts/start.sh"
assert_grep "reports already running" 'Already running' "$WORK/out"
assert_rc 0 "stop.sh stops" "$P/scripts/stop.sh"
sleep 1; kill -0 "$PID" 2>/dev/null && bad "process terminated" || ok "process terminated"
assert_rc 0 "stop when not running" "$P/scripts/stop.sh"
echo 'APP_START_CMD="sleep 300"' > "$P/.env"; echo 'APP_PORT=5000' >> "$P/.env"
if [ "$(uname -s)" = "Darwin" ]; then assert_rc 1 "refuses port 5000 on macOS" "$P/scripts/start.sh"; fi
echo 'APP_START_CMD="exit 3"' > "$P/.env"
assert_rc 1 "start fails when app exits immediately" "$P/scripts/start.sh"
# cleanup
mkdir -p "$P/node_modules/x" "$P/.venv/bin" "$P/sub/__pycache__"; echo a > "$P/keep.txt"
assert_rc 0 "cleanup --dry-run" "$P/scripts/cleanup.sh" --dry-run
[ -d "$P/node_modules" ] && ok "dry-run keeps files" || bad "dry-run keeps files"
assert_rc 0 "cleanup" "$P/scripts/cleanup.sh"
[ ! -d "$P/node_modules" ] && [ ! -d "$P/.venv" ] && [ ! -d "$P/sub/__pycache__" ] && ok "folders removed" || bad "folders removed"
assert_file "unrelated file kept" "$P/keep.txt"
assert_rc 0 "cleanup-images with no images" "$P/scripts/cleanup-images.sh"
assert_rc 0 "cleanup-images --dry-run" "$P/scripts/cleanup-images.sh" --dry-run example/img:1

echo "== project-docs"
P="$(new)"; D="$SK/project-docs/scripts/scaffold_docs.sh"
assert_rc 0 "scaffold docs" bash "$D" --license "Apache-2.0" --name "Demo" "$P"
assert_file "README.md" "$P/README.md"; assert_file "Quickstart" "$P/Docs/Quickstart.md"; assert_file "Architecture" "$P/Docs/Architecture.md"
assert_grep "README title" '^# Demo$' "$P/README.md"
assert_grep "README license" '^Apache-2.0$' "$P/README.md"
assert_grep "README mermaid" '```mermaid' "$P/README.md"
assert_grep "Architecture mermaid" '```mermaid' "$P/Docs/Architecture.md"
echo 'custom' >> "$P/Docs/Quickstart.md"; bash "$D" "$P" >/dev/null
assert_grep "does not overwrite" '^custom$' "$P/Docs/Quickstart.md"
P="$(new)"; printf '# Mine\n' > "$P/README.md"; bash "$D" --license GPL-3.0 "$P" >/dev/null
assert_grep "adds License to existing README" '^GPL-3.0$' "$P/README.md"
assert_grep "existing README content kept" '^# Mine$' "$P/README.md"

echo "== python-env"
P="$(new)"; E="$SK/python-env/scripts/setup_env.sh"
assert_rc 0 "venv without requirements" bash "$E" "$P"
assert_file ".venv created" "$P/.venv"
echo "# none" > "$P/requirements.txt"
assert_rc 0 "sync requirements" bash "$E" "$P"
assert_file "stamp written" "$P/.venv/.requirements.sha256"
assert_rc 0 "second run" bash "$E" "$P"
assert_grep "no-op when unchanged" 'up to date' "$WORK/out"
echo "# changed" >> "$P/requirements.txt"
assert_rc 0 "run after change" bash "$E" "$P"
assert_grep "re-syncs after change" 'synced' "$WORK/out"

echo "== io-folders"
P="$(new)"; I="$SK/io-folders/scripts/io.sh"
assert_rc 1 "inputs fails without input/" bash "$I" inputs "$P"
mkdir -p "$P/input/a/b"; echo 1 > "$P/input/x.txt"; echo 2 > "$P/input/a/b/y.txt"; touch "$P/input/.gitkeep"
bash "$I" inputs "$P" > "$WORK/list"
[ "$(wc -l < "$WORK/list" | tr -d ' ')" = "2" ] && ok "lists nested files, skips .gitkeep" || bad "lists nested files"
assert_grep "includes nested file" 'a/b/y\.txt' "$WORK/list"
OUT="$(bash "$I" output "$P" report)"
assert_file "output/ created" "$P/output"
echo "$OUT" | grep -Eq 'output/[0-9]{8}_[0-9]{6}_report$' && ok "timestamped path" || bad "timestamped path: $OUT"
assert_rc 2 "unknown command" bash "$I" nope "$P"

echo "== container-images"
P="$(new)"; C="$SK/container-images/scripts/lint_containerfile.sh"
assert_rc 0 "template passes lint" bash "$C" "$SK/container-images/templates/Containerfile"
printf 'FROM python:latest\nUSER root\n' > "$P/Dockerfile"
assert_rc 1 ":latest + root fail" bash "$C" "$P/Dockerfile"
printf 'FROM python:3.12\nSHELL ["/bin/bash","-c"]\n' > "$P/Dockerfile"
assert_rc 1 "SHELL fails" bash "$C" "$P/Dockerfile"
printf 'FROM python:3.12\nENV API_KEY=abc123\n' > "$P/Dockerfile"
assert_rc 1 "baked secret fails" bash "$C" "$P/Dockerfile"
printf 'FROM python:3.12\nUSER app\n' > "$P/Dockerfile"
assert_rc 0 "single stage only warns" bash "$C" "$P/Dockerfile"
assert_grep "single-stage warning" 'single-stage' "$WORK/out"
assert_rc 2 "missing file" bash "$C" "$P/none"

echo "== test-gate"
P="$(new)"; T="$SK/test-gate/scripts/run_tests.sh"
assert_rc 2 "no tests -> 2" bash "$T" "$P"
printf 'def f():\n    return 1\n' > "$P/mod.py"
printf 'import unittest, mod\nclass T(unittest.TestCase):\n    def test_f(self):\n        self.assertEqual(mod.f(), 1)\nif __name__ == "__main__":\n    unittest.main()\n' > "$P/test_mod.py"
assert_rc 0 "tests pass" bash "$T" "$P"
printf 'def g():\n    return 2\n' > "$P/other.py"
assert_rc 1 "untested module -> 1" bash "$T" "$P"
assert_grep "reports UNTESTED" 'UNTESTED: .*other\.py' "$WORK/out"
rm "$P/other.py"; sed -i '' 's/== 1/== 99/;s/, 1)/, 99)/' "$P/test_mod.py"
assert_rc 1 "failing test -> 1" bash "$T" "$P"
P="$(new)"; mkdir -p "$P/tests"; printf '#!/usr/bin/env bash\nexit 0\n' > "$P/tests/run_tests.sh"; chmod +x "$P/tests/run_tests.sh"
assert_rc 0 "runs tests/run_tests.sh" bash "$T" "$P"

echo "== project-audit"
P="$(new)"; A="$SK/project-audit/scripts/audit.sh"
assert_rc 1 "empty project fails" bash "$A" "$P"
bash "$SK/project-docs/scripts/scaffold_docs.sh" "$P" >/dev/null
bash "$SK/git-hygiene/scripts/ensure_gitignore.sh" "$P" >/dev/null
bash "$SK/project-lifecycle-scripts/scripts/scaffold_scripts.sh" "$P" >/dev/null
echo 'x=1' > "$P/app.py"
assert_rc 0 "compliant project passes" bash "$A" "$P"
chmod -x "$P/scripts/stop.sh"
assert_rc 1 "detects non-executable script" bash "$A" "$P"
chmod +x "$P/scripts/stop.sh"; echo 'notes' > "$P/NOTES.md"
assert_rc 1 "detects stray document" bash "$A" "$P"
rm "$P/NOTES.md"; echo 'password = "supersecret99"' > "$P/app.py"  # nosecret (test fixture)
assert_rc 1 "detects secret" bash "$A" "$P"

echo "== platform scripts"
assert_rc 0 "validate_skills on real skills" bash "$ROOT/scripts/validate_skills.sh" "$SK"
P="$(new)"; mkdir -p "$P/bad"; printf -- '---\nname: wrong\ndescription: x\n---\n' > "$P/bad/SKILL.md"
assert_rc 1 "validate_skills rejects bad skill" bash "$ROOT/scripts/validate_skills.sh" "$P"
assert_rc 0 "sync_platforms generates" bash "$ROOT/scripts/sync_platforms.sh"
assert_rc 0 "sync_platforms --check in sync" bash "$ROOT/scripts/sync_platforms.sh" --check
assert_grep "CLAUDE.md imports AGENTS.md" '^@\.bob/rules/AGENTS\.md$' "$ROOT/CLAUDE.md"
assert_grep "CLAUDE.md imports git.md" '^@\.bob/rules/git\.md$' "$ROOT/CLAUDE.md"
[ "$(grep -c '^@' "$ROOT/CLAUDE.md")" = "$(ls "$ROOT"/.bob/rules/*.md | wc -l | tr -d ' ')" ] && ok "CLAUDE.md imports every rule" || bad "CLAUDE.md imports every rule"
assert_file "Claude skill copied" "$ROOT/.claude/skills/git-hygiene/SKILL.md"
P="$(new)"
assert_rc 0 "install into project" bash "$ROOT/scripts/install.sh" --target "$P/t"
assert_file "installed Bob skill" "$P/t/.bob/skills/test-gate/SKILL.md"
assert_file "installed Claude skill" "$P/t/.claude/skills/test-gate/SKILL.md"
assert_file "installed CLAUDE.md" "$P/t/CLAUDE.md"
assert_file "installed rules" "$P/t/.bob/rules/git.md"
[ -x "$P/t/.claude/skills/test-gate/scripts/run_tests.sh" ] && ok "installed scripts executable" || bad "installed scripts executable"
assert_rc 2 "install requires target" bash "$ROOT/scripts/install.sh"

echo
echo "Passed: $PASS  Failed: $FAILN"
[ "$FAILN" -eq 0 ]
