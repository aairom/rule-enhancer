#!/usr/bin/env bash
# Validate every skill under a skills directory against the shared IBM Bob / Claude Code format.
# Usage: validate_skills.sh [skills_dir]   (default: .bob/skills)
# Rules checked per skills/<name>/SKILL.md:
#   - starts with YAML frontmatter containing `name` and `description`
#   - name: lowercase letters/digits/hyphens, <= 64 chars, equals the folder name
#   - description: non-empty, <= 1024 chars, single line
#   - required documentation sections: "## Purpose" and "## Usage"
#   - every scripts/*.sh and templates/*.sh is executable
# Exit: 0 valid, 1 problems found
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS="${1:-$ROOT/.bob/skills}"
[ -d "$SKILLS" ] || { echo "skills dir not found: $SKILLS" >&2; exit 2; }

FAIL=0; COUNT=0
err() { echo "  - $1"; FAIL=1; }

for d in "$SKILLS"/*/; do
  [ -d "$d" ] || continue
  n="$(basename "$d")"; f="$d/SKILL.md"; COUNT=$((COUNT+1))
  echo "[$n]"
  [ -f "$f" ] || { err "SKILL.md missing"; continue; }
  [ "$(sed -n 1p "$f")" = "---" ] || { err "no frontmatter"; continue; }
  fm="$(awk 'NR==1{next} /^---$/{exit} {print}' "$f")"
  name="$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -1)"
  desc="$(printf '%s\n' "$fm" | sed -n 's/^description:[[:space:]]*//p' | head -1)"
  [ "$name" = "$n" ] || err "name '$name' != folder '$n'"
  printf '%s' "$name" | grep -Eq '^[a-z0-9-]{1,64}$' || err "invalid name format"
  [ -n "$desc" ] || err "description missing"
  [ "${#desc}" -le 1024 ] || err "description > 1024 chars"
  grep -q '^## Purpose' "$f" || err "missing '## Purpose' section"
  grep -q '^## Usage' "$f"   || err "missing '## Usage' section"
  for s in "$d"scripts/*.sh "$d"templates/*.sh; do
    [ -e "$s" ] || continue
    [ -x "$s" ] || err "not executable: ${s#"$d"}"
  done
done

[ "$COUNT" -gt 0 ] || { echo "no skills found in $SKILLS"; exit 1; }
echo
[ "$FAIL" -eq 0 ] && echo "OK: $COUNT skill(s) valid" || echo "FAILED"
exit "$FAIL"
