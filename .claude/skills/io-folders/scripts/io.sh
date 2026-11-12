#!/usr/bin/env bash
# I/O helper for the input/ and output/ folders.
#   io.sh inputs [project_dir]            -> list every file under input/ recursively (one per line)
#   io.sh output [project_dir] [name]     -> create output/ if needed, print a timestamped path
#                                            e.g. output/20260101_120000_report
set -euo pipefail

CMD="${1:?usage: io.sh inputs|output [project_dir] [name]}"; shift
DIR="${1:-.}"; NAME="${2:-result}"

case "$CMD" in
  inputs)
    [ -d "$DIR/input" ] || { echo "no input/ folder in $DIR" >&2; exit 1; }
    find "$DIR/input" -type f ! -name '.gitkeep' ! -name '.DS_Store' | LC_ALL=C sort
    ;;
  output)
    mkdir -p "$DIR/output"
    echo "$DIR/output/$(date +%Y%m%d_%H%M%S)_${NAME}"
    ;;
  *) echo "unknown command: $CMD" >&2; exit 2;;
esac
