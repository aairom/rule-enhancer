---
name: project-audit
description: Read-only compliance audit that composes the other project skills - checks README with License, Docs/Quickstart.md and Docs/Architecture.md, documents confined to Docs/, .gitignore policy, hard-coded secrets, executable scripts and Containerfile policy. Use before delivering or pushing a project, at the end of a task, or when asked whether a project follows the project rules.
---

# project-audit

## Purpose
One command that verifies the whole rule set instead of re-checking each rule by hand. Orchestrates `git-hygiene --check`, `secure-config`, `container-images` and structure checks. Never modifies files.

## Inputs / Outputs
| Item | Detail |
|---|---|
| Input | `project_dir` (default `.`) |
| Output | `PASS`/`FAIL` line per check with indented details, final `AUDIT PASSED/FAILED` |
| Exit | `0` all pass, `1` any failure |

Checks: README.md · License section · Docs/Quickstart.md · Docs/Architecture.md · no stray documents outside `Docs/` · `.gitignore` policy · secrets scan · `scripts/*.sh` executable · Containerfile/Dockerfile lint (when present).
Unit tests are intentionally separate: run `test-gate`.

## Usage
Paths relative to this skill's directory.

```bash
bash scripts/audit.sh ../..
```

## Remediation map
| Failing check | Fix with |
|---|---|
| README / Quickstart / Architecture / License | `project-docs` |
| .gitignore | `git-hygiene` |
| secrets | `secure-config` |
| script permissions | `chmod +x scripts/*.sh` or `project-lifecycle-scripts` |
| Containerfile | `container-images` |
