#!/usr/bin/env bash
# Idempotently ensure a project's .gitignore contains the required entries.
# Usage: ensure_gitignore.sh [--check] [project_dir]
#   --check   report missing entries and exit 1, change nothing
# Exit: 0 = complete/updated, 1 = entries missing (check mode)
set -euo pipefail

CHECK=0
if [ "${1:-}" = "--check" ]; then CHECK=1; shift; fi
DIR="${1:-.}"
FILE="$DIR/.gitignore"

# Canonical entry list (mirrors .bob/rules/git.md).
ENTRIES=(
  ".env"
  ".env.*"
  "!.env.example"
  "_*/"
  "node_modules/"
  ".venv/"
  "__pycache__/"
  ".playwright-mcp/"
  ".run/"
  "*.onnx"
  "*.onnx.data"
  "*.so"
  "*.tgz"
  "*.tar.gz"
  "*.zip"
  "*.dylib"
  "input/*"
  "!input/.gitkeep"
  "output/*"
  "!output/.gitkeep"
  "AGENTS.md"
  ".bob/mcp.json"
)

MISSING=()
for e in "${ENTRIES[@]}"; do
  if [ ! -f "$FILE" ] || ! grep -qxF -- "$e" "$FILE"; then MISSING+=("$e"); fi
done

if [ "${#MISSING[@]}" -eq 0 ]; then
  echo "OK: $FILE has all required entries"
  exit 0
fi

if [ "$CHECK" -eq 1 ]; then
  echo "MISSING in $FILE:"
  printf '  %s\n' "${MISSING[@]}"
  exit 1
fi

mkdir -p "$DIR"
touch "$FILE"
# Ensure the file ends with a newline before appending.
if [ -s "$FILE" ] && [ "$(tail -c1 "$FILE" | wc -l)" -eq 0 ]; then echo >> "$FILE"; fi
if ! grep -qxF "# --- managed by git-hygiene skill ---" "$FILE"; then
  echo "# --- managed by git-hygiene skill ---" >> "$FILE"
fi
printf '%s\n' "${MISSING[@]}" >> "$FILE"

# input/ and output/ folders are tracked; only their content is ignored.
for d in input output; do
  mkdir -p "$DIR/$d"
  [ -f "$DIR/$d/.gitkeep" ] || touch "$DIR/$d/.gitkeep"
done

echo "UPDATED: $FILE (added ${#MISSING[@]} entries)"
