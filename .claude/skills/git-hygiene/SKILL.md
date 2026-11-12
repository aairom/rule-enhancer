---
name: git-hygiene
description: Create or repair a project's .gitignore so secrets, binaries, node_modules, underscore-prefixed folders, input/output contents, AGENTS.md and .bob/mcp.json are never pushed to GitHub. Use when starting a project, before the first commit or push, or when asked to create, check or fix .gitignore.
---

# git-hygiene

## Purpose
Single, idempotent implementation of the project's Git ignore policy (`.bob/rules/git.md`).

## Inputs
| Argument | Meaning |
|---|---|
| `project_dir` | Target project (default: current directory) |
| `--check` | Report missing entries, exit 1, change nothing |

## Outputs
- `.gitignore` with every required entry appended once (never duplicated, existing lines untouched).
- `input/.gitkeep` and `output/.gitkeep` so both folders are tracked while their content is ignored.
- Exit code: `0` complete/updated, `1` entries missing (`--check`).

## Usage
Paths are relative to this skill's directory.

```bash
bash scripts/ensure_gitignore.sh                # fix current project
bash scripts/ensure_gitignore.sh --check ../..  # audit only
```

## Policy enforced
`.env`/`.env.*` (but not `.env.example`), `_*/` folders, `node_modules/`, `.venv/`, `__pycache__/`, `.playwright-mcp/`, `.run/` (runtime pid/log),
`*.onnx *.onnx.data *.so *.tgz *.tar.gz *.zip *.dylib`, `input/*`, `output/*`, `AGENTS.md`, `.bob/mcp.json`.

## Notes
- Always run before the first push; composes with `project-audit`.
- Works identically in IBM Bob and Claude Code (plain Bash, no platform APIs).
