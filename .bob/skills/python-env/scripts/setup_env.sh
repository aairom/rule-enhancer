#!/usr/bin/env bash
# Create/refresh the project's Python virtual environment with uv (fallback: python -m venv + pip).
# Re-syncs automatically when requirements.txt changed since the last run.
# Usage: setup_env.sh [--force] [project_dir]
set -euo pipefail

FORCE=0; [ "${1:-}" = "--force" ] && { FORCE=1; shift; }
DIR="${1:-.}"
cd "$DIR"

REQ="requirements.txt"
STAMP=".venv/.requirements.sha256"

hash_of() { if command -v shasum >/dev/null; then shasum -a 256 "$1" | cut -d' ' -f1; else sha256sum "$1" | cut -d' ' -f1; fi; }

[ -d .venv ] || NEW=1
NEW="${NEW:-0}"

if [ "$NEW" -eq 1 ]; then
  if command -v uv >/dev/null; then uv venv .venv; else python3 -m venv .venv; fi
  echo "created .venv"
fi

if [ ! -f "$REQ" ]; then echo "no $REQ; environment ready"; exit 0; fi

CUR="$(hash_of "$REQ")"
OLD="$(cat "$STAMP" 2>/dev/null || true)"
if [ "$FORCE" -eq 0 ] && [ "$CUR" = "$OLD" ]; then echo "up to date (requirements unchanged)"; exit 0; fi

if command -v uv >/dev/null; then
  uv pip install --python .venv/bin/python -r "$REQ"
else
  .venv/bin/python -m pip install -r "$REQ"
fi
echo "$CUR" > "$STAMP"
echo "dependencies synced from $REQ"
