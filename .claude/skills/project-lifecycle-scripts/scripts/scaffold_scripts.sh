#!/usr/bin/env bash
# Install the lifecycle script templates into a project's scripts/ folder (chmod +x).
# Usage: scaffold_scripts.sh [--images] [--force] [project_dir]
#   --images  also install cleanup-images.sh (for projects that pull container images)
#   --force   overwrite existing scripts (default: keep existing, per "update, don't recreate")
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TPL="$HERE/../templates"

IMAGES=0; FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in --images) IMAGES=1;; --force) FORCE=1;; *) break;; esac; shift
done
DIR="${1:-.}"
mkdir -p "$DIR/scripts"

FILES=(start.sh stop.sh cleanup.sh)
[ "$IMAGES" -eq 1 ] && FILES+=(cleanup-images.sh)

for f in "${FILES[@]}"; do
  dest="$DIR/scripts/$f"
  if [ -e "$dest" ] && [ "$FORCE" -eq 0 ]; then echo "kept existing: scripts/$f"; else cp "$TPL/$f" "$dest"; echo "installed: scripts/$f"; fi
  chmod +x "$dest"
done

# Document required variables once.
EX="$DIR/.env.example"; touch "$EX"
add() { grep -q "^$1=" "$EX" || echo "$1=$2" >> "$EX"; }
add APP_START_CMD "uv run streamlit run app.py --server.port 8501"
add APP_HOST "localhost"
add APP_PORT "8501"
[ "$IMAGES" -eq 1 ] && add PROJECT_IMAGES "docker.io/library/python:3.12-slim"
echo "Next: set APP_START_CMD in .env, then run scripts/start.sh"
