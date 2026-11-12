---
name: python-env
description: Create and refresh a project-local Python virtual environment using uv (preferred over pip), automatically re-syncing when requirements.txt changes. Use when starting a Python project, adding or changing Python dependencies, or when asked to set up, update or rebuild the venv. Python UIs should prefer Streamlit or Gradio.
---

# python-env

## Purpose
Implements `.bob/rules/python.md`: always a virtual environment, `uv` over `pip`, venv re-synced after `requirements.txt` edits.

## Inputs
| Argument | Meaning |
|---|---|
| `--force` | Reinstall even if requirements are unchanged |
| `project_dir` | Project root (default `.`) |

## Outputs
- `.venv/` in the project; `.venv/.requirements.sha256` change stamp.
- Exit `0` on success; non-zero if installation fails.

## Usage
Paths relative to this skill's directory.

```bash
bash scripts/setup_env.sh ../..      # create or refresh
bash scripts/setup_env.sh --force ../..
```

Run it again **every time** `requirements.txt` is modified (it is a no-op when nothing changed).
Run tools via `uv run ...` or `.venv/bin/python`. `.venv/` is git-ignored by `git-hygiene` and removed by `cleanup.sh` from `project-lifecycle-scripts`.
