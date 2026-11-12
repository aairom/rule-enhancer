---
name: test-gate
description: Verify that all delivered code is unit tested - auto-detects pytest, unittest, npm, Go or Bats, runs the tests and flags Python modules without a test file. Use after writing or changing any code, before reporting a task complete, or when asked to test, validate or check coverage of the code.
---

# test-gate

## Purpose
Single gate for the rules "code must be unit tested", "all provided code should be tested" and "always test the functionality of the code you provide".

## Inputs / Outputs
| Item | Detail |
|---|---|
| Input | `project_dir` (default `.`) |
| Runner detection order | `tests/run_tests.sh` → `package.json` `test` script → `go.mod` → Python `test_*.py`/`*_test.py` (pytest if installed, else unittest; uses `.venv` when present) → Bats |
| Output | Runner output, `UNTESTED: <file>` lines, final `OK`/`FAIL` |
| Exit | `0` pass · `1` failures or untested modules · `2` no runner/tests found |

## Usage
Paths relative to this skill's directory.

```bash
bash scripts/run_tests.sh ../..
```

## Procedure
1. Write tests next to the code (`tests/` or `test_<module>.py`), covering normal, edge and failure paths.
2. Run the gate; fix until exit `0`.
3. Exit `2` on code that exists means tests are missing - create them, do not skip the gate.
4. Never report completion with a failing gate.
