#!/usr/bin/env bash
# Lint a Dockerfile/Containerfile against the project's container policy.
# Usage: lint_containerfile.sh <path-to-Dockerfile-or-Containerfile>
# Exit: 0 = pass (warnings allowed), 1 = violations
set -uo pipefail
F="${1:?usage: lint_containerfile.sh <file>}"
[ -f "$F" ] || { echo "not found: $F" >&2; exit 2; }

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }
warn() { echo "WARN: $1"; }

STAGES="$(grep -ciE '^[[:space:]]*FROM[[:space:]]' "$F")"
[ "$STAGES" -ge 2 ] || warn "single-stage build; use multi-stage if any build tools are needed"
grep -qiE '^[[:space:]]*FROM[^#]*:latest([[:space:]]|$)' "$F" && fail "base image uses :latest (pin a tag)"
grep -qiE '^[[:space:]]*USER[[:space:]]+(root|0)\b' "$F" && fail "final USER is root"
grep -qiE '^[[:space:]]*USER[[:space:]]' "$F" || warn "no USER instruction (runs as root)"
grep -qiE '^[[:space:]]*(SHELL|ONBUILD)[[:space:]]' "$F" && fail "Docker-only instruction (SHELL/ONBUILD) breaks Containerfile compatibility"
grep -qE 'pip install' "$F" && ! grep -qE 'pip install[^\\]*--no-cache-dir' "$F" && warn "pip install without --no-cache-dir"
grep -qE 'apt-get install' "$F" && ! grep -qE 'rm -rf /var/lib/apt/lists' "$F" && warn "apt-get install without cleaning /var/lib/apt/lists"
grep -qiE '^[[:space:]]*(ENV|ARG)[[:space:]]+[A-Za-z_]*(KEY|SECRET|TOKEN|PASSWORD)[A-Za-z_]*[= ][^$[:space:]]' "$F" && fail "secret value baked into ENV/ARG"

[ "$FAIL" -eq 0 ] && echo "OK: $F"
exit "$FAIL"
