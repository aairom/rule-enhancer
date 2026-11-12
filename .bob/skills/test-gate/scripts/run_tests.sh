#!/usr/bin/env bash
# Detect the project's test runner and run it; also flag source files that have no test.
# Usage: run_tests.sh [project_dir]
# Exit: 0 tests pass, 1 failures or untested code, 2 no runner / no tests found
set -uo pipefail
DIR="${1:-.}"
cd "$DIR"

RC=0
PRUNE=( -name node_modules -o -name .venv -o -name __pycache__ -o -name .git -o -name output -o -name input -o -name .bob -o -name .claude )

# ---- 1. Run tests ----
RAN=0
if [ -x tests/run_tests.sh ] || [ -f tests/run_tests.sh ]; then
  echo "== tests/run_tests.sh"; bash tests/run_tests.sh; RC=$?; RAN=1
elif [ -f package.json ] && grep -q '"test"' package.json; then
  echo "== npm test"; npm test --silent; RC=$?; RAN=1
elif [ -f go.mod ]; then
  echo "== go test"; go test ./...; RC=$?; RAN=1
elif find . \( "${PRUNE[@]}" \) -prune -o \( -name 'test_*.py' -o -name '*_test.py' \) -print | grep -q .; then
  if [ -x .venv/bin/python ]; then PY=.venv/bin/python; else PY=python3; fi
  if "$PY" -c 'import pytest' 2>/dev/null; then echo "== pytest"; "$PY" -m pytest -q; RC=$?
  else echo "== unittest"; "$PY" -m unittest discover -v; RC=$?; fi
  RAN=1
elif find . \( "${PRUNE[@]}" \) -prune -o -name '*.bats' -print | grep -q . && command -v bats >/dev/null; then
  echo "== bats"; bats -r .; RC=$?; RAN=1
fi
if [ "$RAN" -eq 0 ]; then echo "No test runner or tests found"; exit 2; fi

# ---- 2. Untested Python modules (name-based heuristic) ----
MISSING=0
while IFS= read -r src; do
  base="$(basename "$src" .py)"
  case "$base" in __init__|test_*|*_test|conftest|setup) continue;; esac
  if ! find . \( "${PRUNE[@]}" \) -prune -o \( -name "test_${base}.py" -o -name "${base}_test.py" \) -print | grep -q .; then
    echo "UNTESTED: $src"; MISSING=1
  fi
done < <(find . \( "${PRUNE[@]}" \) -prune -o -name '*.py' -print)

[ "$RC" -ne 0 ] && { echo "FAIL: tests failed"; exit 1; }
[ "$MISSING" -ne 0 ] && { echo "FAIL: add tests for the modules above"; exit 1; }
echo "OK: tests pass and every module has a test"
