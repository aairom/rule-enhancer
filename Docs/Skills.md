# Skills catalog

All skills live in `.bob/skills/<name>/` and use the same `SKILL.md` format on IBM Bob and Claude Code
(YAML frontmatter `name` + `description`; Markdown body). Paths below are relative to the skill folder.
Every script exits `0` on success and prints human-readable output.

## git-hygiene
- **Purpose:** enforce the `.gitignore` policy (secrets, binaries, `_*/`, `node_modules`, `.venv`, `__pycache__`, `.playwright-mcp`, `AGENTS.md`, `.bob/mcp.json`, input/output content).
- **Inputs:** `[--check] [project_dir]`
- **Outputs:** updated `.gitignore`, `input/.gitkeep`, `output/.gitkeep`; exit `1` in `--check` when entries are missing.
- **Example:** `bash scripts/ensure_gitignore.sh --check .`

## secure-config
- **Purpose:** no hard-coded credentials, e-mails, tokens (and with `--strict`, URLs); `.env` + `.env.example` pattern.
- **Inputs:** `[--strict] [project_dir]`; add `nosecret` on a line to suppress a reviewed finding.
- **Outputs:** findings by category, warning for missing `.env.example`; exit `1` on findings.
- **Example:** `bash scripts/scan_secrets.sh --strict .`

## project-lifecycle-scripts
- **Purpose:** standard `scripts/start.sh` (detached, prints URL), `stop.sh` (graceful), `cleanup.sh`, `cleanup-images.sh`.
- **Inputs:** `[--images] [--force] [project_dir]`; runtime config in `.env`: `APP_START_CMD`, `APP_HOST`, `APP_PORT`, `PROJECT_IMAGES`, `STOP_TIMEOUT`.
- **Outputs:** executable scripts, `.env.example` entries, `.run/app.pid`, `.run/app.log` at run time.
- **Example:** `bash scripts/scaffold_scripts.sh --images .`

## project-docs
- **Purpose:** `README.md` (architecture + workflow Mermaid, License), `Docs/Quickstart.md`, `Docs/Architecture.md`.
- **Inputs:** `[--license TYPE] [--name NAME] [project_dir]`
- **Outputs:** missing files created; existing files untouched except a missing License section is appended.
- **Example:** `bash scripts/scaffold_docs.sh --license Apache-2.0 .`

## python-env
- **Purpose:** `.venv` with `uv`; automatic re-sync when `requirements.txt` changes (hash stamp).
- **Inputs:** `[--force] [project_dir]`
- **Outputs:** `.venv/`, `.venv/.requirements.sha256`.
- **Example:** `bash scripts/setup_env.sh .`

## io-folders
- **Purpose:** recursive input listing and timestamped output names.
- **Inputs:** `inputs [dir]` or `output [dir] [name]`
- **Outputs:** file list, or `output/YYYYmmdd_HHMMSS_<name>` (creates `output/`).
- **Example:** `bash scripts/io.sh output . summary`

## container-images
- **Purpose:** small multi-stage Podman/Docker-compatible images.
- **Inputs:** `scripts/lint_containerfile.sh <file>`; `templates/Containerfile`.
- **Outputs:** `FAIL:`/`WARN:` lines; exit `1` on `:latest`, root user, Docker-only instructions, baked secrets.
- **Example:** `bash scripts/lint_containerfile.sh Containerfile`

## test-gate
- **Purpose:** run the project's tests and flag untested Python modules.
- **Inputs:** `[project_dir]`; auto-detects `tests/run_tests.sh`, npm, Go, pytest/unittest, Bats.
- **Outputs:** runner output, `UNTESTED:` lines; exit `0` pass, `1` fail/untested, `2` nothing to run.
- **Example:** `bash scripts/run_tests.sh .`

## project-audit
- **Purpose:** read-only compliance check composed from the other skills.
- **Inputs:** `[project_dir]`
- **Outputs:** PASS/FAIL per check, `AUDIT PASSED|FAILED`; exit `1` on any failure.
- **Example:** `bash scripts/audit.sh .`

## Platform compatibility

| Aspect | IBM Bob | Claude Code |
|---|---|---|
| Rules | `.bob/rules/*.md` loaded automatically | `CLAUDE.md` with `@.bob/rules/<file>` imports (generated) |
| Skills | `.bob/skills/<name>/SKILL.md` (project) or `~/.bob/skills` (global) | `.claude/skills/<name>/SKILL.md` (project) or `~/.claude/skills` (global) |
| Activation | by `description` match | by `description` match, or by name |
| Scripts | referenced relative to the skill folder | same |

Skill rules respected: `name` is lowercase/digits/hyphens, equals the folder name, at most 64 characters; `description` is one line, at most 1024 characters, and states what the skill does and when to use it. `scripts/validate_skills.sh` enforces this.

## Adding a skill
1. Create `.bob/skills/<name>/SKILL.md` with `## Purpose` and `## Usage` sections and scripts in `scripts/`.
2. Add tests to `tests/run_tests.sh`.
3. Run `scripts/validate_skills.sh`, `scripts/sync_platforms.sh`, `tests/run_tests.sh`.
