#!/usr/bin/env bash
# Compose the project skills into one compliance audit (read-only).
# Usage: audit.sh [project_dir]
# Exit: 0 all checks pass, 1 at least one check failed
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SK="$HERE/../.."   # skills root (works for .bob/skills and .claude/skills)
DIR="${1:-.}"

FAIL=0
check() { # $1 label, rest = command
  local label="$1"; shift
  if "$@" >/tmp/audit_out.$$ 2>&1; then echo "PASS  $label"
  else echo "FAIL  $label"; sed 's/^/        /' /tmp/audit_out.$$; FAIL=1; fi
  rm -f /tmp/audit_out.$$
}
exists() { [ -e "$DIR/$1" ] || { echo "missing: $1"; return 1; }; }
executable_scripts() {
  local bad=0
  for s in "$DIR"/scripts/*.sh; do [ -e "$s" ] || continue; [ -x "$s" ] || { echo "not executable: $s"; bad=1; }; done
  return "$bad"
}
license_in_readme() { grep -qiE '^#{1,3} +licen[cs]e' "$DIR/README.md" 2>/dev/null || { echo "README.md has no License section"; return 1; }; }
docs_only_in_docs() {
  local bad=0
  while IFS= read -r f; do
    case "$(basename "$f")" in README.md|AGENTS.md|CLAUDE.md|LICENSE.md|SKILL.md) ;; *) echo "document outside Docs/: $f"; bad=1;; esac
  done < <(find "$DIR" -maxdepth 1 -type f \( -name '*.md' -o -name '*.docx' -o -name '*.pdf' \))
  return "$bad"
}

check "README.md present"            exists README.md
check "License section in README"    license_in_readme
check "Docs/Quickstart.md present"   exists Docs/Quickstart.md
check "Docs/Architecture.md present" exists Docs/Architecture.md
check "documents live in Docs/"      docs_only_in_docs
check ".gitignore policy"            bash "$SK/git-hygiene/scripts/ensure_gitignore.sh" --check "$DIR"
check "no hard-coded secrets"        bash "$SK/secure-config/scripts/scan_secrets.sh" "$DIR"
check "scripts are executable"       executable_scripts
for cf in Containerfile Dockerfile; do
  [ -f "$DIR/$cf" ] && check "$cf policy" bash "$SK/container-images/scripts/lint_containerfile.sh" "$DIR/$cf"
done

echo
[ "$FAIL" -eq 0 ] && echo "AUDIT PASSED" || echo "AUDIT FAILED"
echo "(run test-gate separately for the unit tests)"
exit "$FAIL"
