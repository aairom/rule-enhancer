# Git
Always provide a `.gitignore`. Skill: `git-hygiene` (idempotent; `--check` audits).
- Ignore `.env` files and any folder whose name starts with `_` (e.g. `_sources/`, `_images/`, `_docs/`).
- Ignore, if present: `*.onnx`, `*.onnx.data`, `*.so`, `*.tgz`, `*.tar.gz`, `*.zip`, `*.dylib`.
- Ignore `node_modules/`, `.playwright-mcp/`, `AGENTS.md`, `.bob/mcp.json`, `.bob/audit/`.
- `input/` and `output/` folders are synced (keep with `.gitkeep`); their content is ignored.
