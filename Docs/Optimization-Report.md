# Optimization report

Original rules are preserved unmodified in `output/<timestamp>/original-rules/` (git-ignored content).

## Measured result
| Metric | Before | After |
|---|---|---|
| Rule files | 15 | 15 (same names, so existing references keep working) |
| Words in always-loaded rules | 866 | 739 (-15%) |
| Lines | 85 | 90 (+5: the rule-to-skill map table in `AGENTS.md`) |
| Procedures that are executable and tested | 0 | 9 skills, 110 test assertions |

Word count falls only modestly because every requirement was kept. The real gain is that multi-step procedures moved out of the always-loaded context into on-demand skills, and they are now verifiable.

## Redundancies removed
| Duplicate | Was in | Now owned by |
|---|---|---|
| "Code must be unit tested" ×3 | AGENTS.md (Code, Unit Test), unit-test.md | `unit-test.md` + `test-gate`; AGENTS.md links to it |
| `.gitignore` always created | git.md, mode-change.md | `git.md` + `git-hygiene` |
| Docs in `Docs/`, README exception | documents.md, project-structure.md | `documents.md`; structure rule points to it |
| Scripts in `scripts/` | automation.md, project-structure.md | `project-structure.md`; automation lists only script behaviour |
| "No hard-coded info" ×2 | security.md (two bullets) | one bullet |
| input/output folders synced, content ignored | git.md ×2, input-output-folders.md | `git.md` one bullet |
| English for implementation / chat | language.md ×2 | one bullet |
| Port 5000 AirDrop | macos.md | enforced in `start.sh` |

## Fixes to the original text
| Issue | Resolution |
|---|---|
| `automation.md`: "node-modules" | corrected to `node_modules` |
| `containers.md`: "optimized optimized" | removed |
| `mode-change.md`: `./bob/artifacts` | treated as `.bob/artifacts` (assumed typo, noted in the rule) |
| `project-structure.md`: "Structur", "overrights", "AGENTS.MD" | corrected |
| `AGENTS.md`: "Licence", "Readme.md" | "License", `README.md` |
| `AGENTS.md` ignores itself via git.md (AGENTS.md excluded from push) but this repo ships `.bob/rules/AGENTS.md` | `.gitignore` here re-includes `!.bob/rules/AGENTS.md`; decide whether you want that |
| `local-llm.md`: llama.cpp "port 8080" and base URL on port 9931 | **unresolved conflict**, flagged in the rule; verify which is live. URL should come from `.env` (`LLM_BASE_URL`) per the security rule |

## Behaviour added by the skills (not in the original text)
- `.gitignore` also covers `.venv/`, `__pycache__/`, `.run/` (needed by the cleanup/launch rules) and `!.env.example`.
- `start.sh` refuses port 5000 on macOS and is idempotent.
- `scan_secrets.sh` honours a `nosecret` suppression marker.
- `test-gate` also fails when a Python module has no test file (strict reading of "all code must be tested"; name-based heuristic).

## Bug found by the tests
`scan_secrets.sh` initially always exited 0 (a counter was set inside a pipeline subshell). Fixed with process substitution; covered by tests.

## Known limitations
- Skills are verified here on macOS with Bash 3.2; Claude Code activation was not exercised against a live Claude Code session. The format follows the documented `SKILL.md` convention and the `CLAUDE.md` `@` import syntax.
- `secure-config` is a regex scanner, not a replacement for a dedicated secret scanner.
- `test-gate` untested-module detection only understands Python naming.
- Rules cannot enforce skill use by themselves; they name the skill and the agent decides to run it.
