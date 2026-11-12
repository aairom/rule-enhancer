#!/usr/bin/env bash
# Delete container images pulled/built for this project. Works with podman (preferred) or docker.
# Images are listed in .env as PROJECT_IMAGES (space-separated) or passed as arguments.
# Usage: cleanup-images.sh [--dry-run] [image ...]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$ROOT/.env" ]; then set -a; . "$ROOT/.env"; set +a; fi

DRY=0; [ "${1:-}" = "--dry-run" ] && { DRY=1; shift; }
IMAGES=("$@")
if [ "${#IMAGES[@]}" -eq 0 ] && [ -n "${PROJECT_IMAGES:-}" ]; then read -r -a IMAGES <<< "$PROJECT_IMAGES"; fi
if [ "${#IMAGES[@]}" -eq 0 ]; then echo "No images given (set PROJECT_IMAGES in .env or pass names)"; exit 0; fi

ENGINE="$(command -v podman || command -v docker || true)"
[ -n "$ENGINE" ] || { echo "ERROR: neither podman nor docker found" >&2; exit 1; }

for img in "${IMAGES[@]}"; do
  if [ "$DRY" -eq 1 ]; then echo "would remove: $img"; continue; fi
  "$ENGINE" rmi -f "$img" >/dev/null 2>&1 && echo "removed: $img" || echo "skip (not present): $img"
done
