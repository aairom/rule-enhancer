# Quickstart

This project refactors the 15 rules in `.bob/rules/` (same filenames, backward compatible) and adds 9 reusable skills that work in both IBM Bob and Claude Code. Skills follow the Bob documentation and the Claude Code `SKILL.md` convention.

## Use in this repository
```bash
tests/run_tests.sh                 # all tests (expects: Passed: 110  Failed: 0)
scripts/validate_skills.sh         # skills valid for Bob and Claude Code
scripts/sync_platforms.sh --check  # generated Claude files up to date?
```

> **Test status:** 110 tests pass with 0 failures, run on macOS with Bash 3.2 only. The Claude Code output has **not yet been tested in a live Claude Code session**.

## Install into another project
```bash
scripts/install.sh --target /path/to/project                     # both (default)
scripts/install.sh --target /path/to/project --platform bob      # Bob only
scripts/install.sh --target /path/to/project --platform claude   # Claude Code only
scripts/install.sh --global --platform claude                    # skills only, to ~/.claude
```

`--platform` takes `bob`, `claude` or `both` (default):

| Value | Installed into the target |
|---|---|
| `bob` | `.bob/rules/*.md`, `.bob/skills/*/` |
| `claude` | `CLAUDE.md` (imports the rules with `@.bob/rules/...`), `.claude/skills/*/`, and `.bob/rules/` so those imports resolve |
| `both` | All of the above |

`--global` installs skills only (`~/.bob/skills`, `~/.claude/skills`); rules are project-specific and are skipped.

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

## Troubleshooting and known issues

| Symptom | Cause and fix |
|---|---|
| `scan_secrets.sh` reports clean on a project with secrets | **Fixed.** `report()` ran in a pipeline subshell, so the `FOUND` flag was lost and the exit status was always 0. It now runs in the main shell through process substitution (`report "label" < <(grep ...)`). If you copied an older version of the script, reinstall with `scripts/install.sh`. Covered by the `secure-config` tests. |
| `project-audit` flags a secret in test fixtures | Add `nosecret` on the reviewed line, as done in `tests/run_tests.sh`. |
| Mermaid error `Lexical error ... documents vars in .env.example .->` in `Docs/Architecture.md` | **Fixed.** Dotted edges with inline text (`-. text .->`) fail to parse when the text contains `.env.example`. Use `-.->|"label"|` and quote node labels; avoid dots in node IDs (use `R_GIT["git.md"]`, not `git.md`). All 3 diagrams in the file now render with the Mermaid CLI. |
| `CLAUDE.md` or `.claude/skills` out of date | Run `scripts/sync_platforms.sh`, then `scripts/sync_platforms.sh --check`. |
| `--platform claude` also created `.bob/rules/` | Expected: `CLAUDE.md` imports each rule from there. |
| llama.cpp port 8080 vs 9931 | **Open.** Conflict in `.bob/rules/local-llm.md`; verify which is live and keep one. |

See [Optimization-Report.md](Optimization-Report.md) for the full change list and [Architecture.md](Architecture.md) for diagrams.
