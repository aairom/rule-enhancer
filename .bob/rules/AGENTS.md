# Project Development Rules (index and core)

Precedence: this folder overrides global `~/.bob` rules. Mode-specific rules (`.bob/rules-{mode}/`) override these.
Procedures live in skills (`.bob/skills/`); rules state *what*, skills do *how*. Prefer running the skill script over re-deriving the steps.

## Core
- If the task or project provides links to source repositories, check them before implementing.
- Code is well structured, commented, maintainable, and tested (see `unit-test.md`).
- When fixing bugs or enhancing, update the existing documents and scripts; do not create parallel copies.
- Never delete files in folders you did not create.
- Web search, when needed, goes through the configured MCP servers.
- Document the open-source **License** type in `README.md` (skill `project-docs`).

## Rule map (single owner per topic)
| Topic | Rule file | Skill |
|---|---|---|
| Language | `language.md` | - |
| Tests | `unit-test.md` | `test-gate` |
| Layout, docs | `project-structure.md`, `documents.md` | `project-docs` |
| Scripts | `automation.md` | `project-lifecycle-scripts` |
| Git | `git.md` | `git-hygiene` |
| Secrets | `security.md` | `secure-config` |
| Input/output | `input-output-folders.md` | `io-folders` |
| Python, UI | `python.md`, `ui.md` | `python-env` |
| Containers | `containers.md` | `container-images` |
| Environment | `local-llm.md`, `macos.md` | - |
| Modes, artifacts | `mode-change.md` | - |
| Final compliance check | - | `project-audit` |
