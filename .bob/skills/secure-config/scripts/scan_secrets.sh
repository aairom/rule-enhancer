#!/usr/bin/env bash
# Scan a project for hard-coded secrets / personal data and check .env.example.
# Usage: scan_secrets.sh [--strict] [project_dir]
#   --strict  also flag hard-coded http(s):// URLs in source files
# Suppress a reviewed line by adding the marker "nosecret" on it.
# Exit: 0 = clean, 1 = findings
set -uo pipefail

STRICT=0
if [ "${1:-}" = "--strict" ]; then STRICT=1; shift; fi
DIR="${1:-.}"

EXCL=(--exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.venv
      --exclude-dir=__pycache__ --exclude-dir=input --exclude-dir=output
      --exclude-dir=.bob --exclude-dir=.claude --exclude-dir=.run
      --exclude=.env.example --exclude=*.lock --exclude=package-lock.json)

FOUND=0
report() { # $1 label, stdin = matches
  local out
  out="$(grep -v 'nosecret' || true)"
  if [ -n "$out" ]; then
    echo "[$1]"; echo "$out" | sed 's/^/  /'; FOUND=1
  fi
}

# Quoted literal assigned to a secret-looking name (env references like ${X} are skipped).
report "hard-coded credential" < <(grep -rIEin "${EXCL[@]}" \
  "(api[_-]?key|secret|token|passwd|password)[[:space:]]*[:=][[:space:]]*[\"'][^\"'\$]{8,}[\"']" "$DIR" \
  2>/dev/null)

# Well-known token shapes.
report "token/private key" < <(grep -rIEn "${EXCL[@]}" \
  'AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{36}|-----BEGIN [A-Z ]*PRIVATE KEY-----' "$DIR" \
  2>/dev/null)

# E-mail addresses in non-markdown files (example.com/org ignored).
report "hard-coded e-mail" < <(grep -rIEn "${EXCL[@]}" --exclude=*.md --exclude=LICENSE* \
  '[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}' "$DIR" \
  2>/dev/null | grep -Ev '@example\.(com|org)')

if [ "$STRICT" -eq 1 ]; then
  report "hard-coded URL" < <(grep -rIEn "${EXCL[@]}" \
    --include=*.py --include=*.js --include=*.ts --include=*.tsx --include=*.jsx \
    --include=*.java --include=*.go --include=*.rb --include=*.sh \
    --include=*.yaml --include=*.yml --include=*.toml \
    'https?://' "$DIR" 2>/dev/null)
fi

if [ ! -f "$DIR/.env.example" ]; then
  echo "WARN: no .env.example in $DIR (required when the app needs configuration)"
fi

if [ "$FOUND" -eq 0 ]; then echo "OK: no hard-coded secrets found in $DIR"; exit 0; fi
echo "FAIL: move values to .env (and document them in .env.example), or mark reviewed lines with 'nosecret'"
exit 1
