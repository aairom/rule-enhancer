#!/usr/bin/env bash
# End-of-project cleanup: remove node_modules, .venv, __pycache__ and runtime state.
# Usage: cleanup.sh [--dry-run]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1

# Stop the app first if it is running.
[ -x "$ROOT/scripts/stop.sh" ] && [ "$DRY" -eq 0 ] && "$ROOT/scripts/stop.sh" || true

COUNT=0
while IFS= read -r p; do
  COUNT=$((COUNT+1))
  if [ "$DRY" -eq 1 ]; then echo "would remove: $p"; else rm -rf "$p"; echo "removed: $p"; fi
done < <(find "$ROOT" \( -name node_modules -o -name .venv -o -name __pycache__ -o -name .run \) \
           -prune -not -path "$ROOT/.git/*" -print)
echo "Done ($COUNT item(s), dry-run=$DRY)"
