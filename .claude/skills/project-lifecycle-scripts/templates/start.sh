#!/usr/bin/env bash
# Launch the application detached and print its URL.
# Configuration comes from .env (see .env.example): APP_START_CMD, APP_HOST, APP_PORT.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Load .env without executing it.
if [ -f .env ]; then set -a; . ./.env; set +a; fi

: "${APP_START_CMD:?Set APP_START_CMD in .env (e.g. 'uv run streamlit run app.py --server.port \$APP_PORT')}"
APP_HOST="${APP_HOST:-localhost}"
APP_PORT="${APP_PORT:-8501}"
if [ "$APP_PORT" = "5000" ] && [ "$(uname -s)" = "Darwin" ]; then
  echo "ERROR: port 5000 is reserved for AirDrop on macOS; choose another APP_PORT" >&2; exit 1
fi

RUN_DIR="$ROOT/.run"; PID_FILE="$RUN_DIR/app.pid"; LOG_FILE="$RUN_DIR/app.log"
mkdir -p "$RUN_DIR"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "Already running (pid $(cat "$PID_FILE")): http://$APP_HOST:$APP_PORT"; exit 0
fi

nohup bash -c "$APP_START_CMD" >"$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"
sleep 1
if ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "ERROR: application exited immediately; see $LOG_FILE" >&2; rm -f "$PID_FILE"; exit 1
fi
echo "Application started (pid $(cat "$PID_FILE"))"
echo "URL: http://$APP_HOST:$APP_PORT"
echo "Logs: $LOG_FILE"
