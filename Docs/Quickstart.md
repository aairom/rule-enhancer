# Quickstart

## Use in this repository
```bash
tests/run_tests.sh                 # all tests (expects: Failed: 0)
scripts/validate_skills.sh         # skills valid for Bob and Claude Code
scripts/sync_platforms.sh --check  # generated Claude files up to date?
```

## Install into another project
```bash
scripts/install.sh --target /path/to/project --platform both   # bob | claude | both
scripts/install.sh --global --platform claude                  # skills only, to ~/.claude
```
Result in the target:
- IBM Bob: `.bob/rules/*.md`, `.bob/skills/*/`
- Claude Code: `CLAUDE.md` (imports the rules with `@.bob/rules/...`), `.claude/skills/*/`

## Everyday skill commands
Paths shown from the project root after installing to `.bob/skills/`.
```bash
bash .bob/skills/project-docs/scripts/scaffold_docs.sh --license MIT .
bash .bob/skills/git-hygiene/scripts/ensure_gitignore.sh .
bash .bob/skills/project-lifecycle-scripts/scripts/scaffold_scripts.sh .
bash .bob/skills/python-env/scripts/setup_env.sh .
bash .bob/skills/project-audit/scripts/audit.sh .
bash .bob/skills/test-gate/scripts/run_tests.sh .
```
In either assistant, simply ask for the outcome ("set up the project docs", "audit this project"); the skill descriptions let the agent pick the right one. In Claude Code you can also invoke a skill by name.

## Editing rules or skills
1. Edit under `.bob/` only.
2. `scripts/sync_platforms.sh` to regenerate the Claude layout.
3. `tests/run_tests.sh` must end with `Failed: 0`.

## Requirements
Bash 3.2+ (macOS default is fine), `grep`, `sed`, `find`. Optional: `uv` (python-env), `podman` (cleanup-images, builds).
