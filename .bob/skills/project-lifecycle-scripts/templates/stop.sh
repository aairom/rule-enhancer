#!/usr/bin/env bash
# Gracefully stop the application started by start.sh (SIGTERM, then SIGKILL after a timeout).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="$ROOT/.run/app.pid"
TIMEOUT="${STOP_TIMEOUT:-15}"

if [ ! -f "$PID_FILE" ]; then echo "Not running (no pid file)"; exit 0; fi
PID="$(cat "$PID_FILE")"
if ! kill -0 "$PID" 2>/dev/null; then echo "Not running (stale pid $PID)"; rm -f "$PID_FILE"; exit 0; fi

# Stop the whole process group when possible so child servers die too.
pkill -TERM -P "$PID" 2>/dev/null || true
kill -TERM "$PID" 2>/dev/null || true
for _ in $(seq 1 "$TIMEOUT"); do
  kill -0 "$PID" 2>/dev/null || { rm -f "$PID_FILE"; echo "Application stopped"; exit 0; }
  sleep 1
done
echo "Graceful stop timed out after ${TIMEOUT}s; forcing"
pkill -KILL -P "$PID" 2>/dev/null || true
kill -KILL "$PID" 2>/dev/null || true
rm -f "$PID_FILE"
echo "Application killed"
