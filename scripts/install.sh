#!/usr/bin/env bash
# Install the skills and rules into another project or the user's global config.
# Usage: install.sh --target <project_dir> [--platform bob|claude|both] [--global]
#   --global  install into ~/.bob and/or ~/.claude instead of a project
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TARGET=""; PLATFORM="both"; GLOBAL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --target)   TARGET="${2:?}"; shift 2;;
    --platform) PLATFORM="${2:?}"; shift 2;;
    --global)   GLOBAL=1; shift;;
    *) echo "unknown option: $1" >&2; exit 2;;
  esac
done
case "$PLATFORM" in bob|claude|both) ;; *) echo "platform must be bob|claude|both" >&2; exit 2;; esac
if [ "$GLOBAL" -eq 1 ]; then BOBDIR="$HOME/.bob"; CLDIR="$HOME/.claude"
else
  [ -n "$TARGET" ] || { echo "--target required (or --global)" >&2; exit 2; }
  mkdir -p "$TARGET"; BOBDIR="$TARGET/.bob"; CLDIR="$TARGET/.claude"
fi

if [ "$PLATFORM" != "claude" ]; then
  mkdir -p "$BOBDIR/skills"; cp -R "$ROOT/.bob/skills/." "$BOBDIR/skills/"
  if [ "$GLOBAL" -eq 0 ]; then mkdir -p "$BOBDIR/rules"; cp "$ROOT/.bob/rules/"*.md "$BOBDIR/rules/"; fi
  echo "Bob: installed into $BOBDIR"
fi
if [ "$PLATFORM" != "bob" ]; then
  mkdir -p "$CLDIR/skills"; cp -R "$ROOT/.bob/skills/." "$CLDIR/skills/"
  if [ "$GLOBAL" -eq 0 ]; then
    mkdir -p "$TARGET/.bob/rules"; cp "$ROOT/.bob/rules/"*.md "$TARGET/.bob/rules/"
    cp "$ROOT/CLAUDE.md" "$TARGET/CLAUDE.md"
  fi
  echo "Claude Code: installed into $CLDIR"
fi
find "$BOBDIR/skills" "$CLDIR/skills" -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
