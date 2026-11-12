---
name: project-lifecycle-scripts
description: Scaffold the standard scripts/ folder for a project - start.sh (detached launch that prints the URL), stop.sh (graceful shutdown), cleanup.sh (removes node_modules, .venv, __pycache__) and optionally cleanup-images.sh (removes pulled container images) - all executable. Use when creating a runnable application, adding a local server, or finishing a project.
---

# project-lifecycle-scripts

## Purpose
One tested set of Bash templates replaces hand-written launch/stop/cleanup scripts (`.bob/rules/automation.md`, `project-structure.md`).

## Inputs
| Argument | Meaning |
|---|---|
| `project_dir` | Target project (default `.`) |
| `--images` | Also install `cleanup-images.sh` (project pulls container images) |
| `--force` | Overwrite existing scripts (default keeps them: update, don't recreate) |

Runtime configuration (in `.env`, documented in `.env.example` automatically): `APP_START_CMD`, `APP_HOST`, `APP_PORT`, `PROJECT_IMAGES`.

## Outputs
`scripts/start.sh`, `scripts/stop.sh`, `scripts/cleanup.sh` (+ `scripts/cleanup-images.sh`), all `chmod +x`; `.env.example` entries.

| Script | Behaviour |
|---|---|
| `start.sh` | Runs `APP_START_CMD` detached with pid/log in `.run/`, prints `URL: http://host:port`; refuses port 5000 on macOS (AirDrop); idempotent |
| `stop.sh` | SIGTERM (incl. children), waits `STOP_TIMEOUT` (15s), then SIGKILL |
| `cleanup.sh [--dry-run]` | Stops the app, removes `node_modules`, `.venv`, `__pycache__`, `.run` |
| `cleanup-images.sh [--dry-run] [img...]` | `podman rmi` (fallback docker) for `PROJECT_IMAGES` |

## Usage
Paths relative to this skill's directory.

```bash
bash scripts/scaffold_scripts.sh --images ../..    # install into project root
# then, in the project:
scripts/start.sh && scripts/stop.sh
scripts/cleanup.sh --dry-run
```

A local server must start with a single command: set `APP_START_CMD` so `scripts/start.sh` is that command.
