---
name: io-folders
description: Read all input documents recursively from the project's input/ folder and write results to output/ with timestamped names (creating output/ if absent). Use when an application or task consumes input documents or must save generated results, reports or exports.
---

# io-folders

## Purpose
Implements `.bob/rules/input-output-folders.md` with a single shared convention.

## Inputs / Outputs
| Command | Result |
|---|---|
| `io.sh inputs [project_dir]` | Every file under `input/` (recursive, sorted, ignoring `.gitkeep`, `.DS_Store`); exit 1 if `input/` missing |
| `io.sh output [project_dir] [name]` | Creates `output/` if needed; prints `output/YYYYmmdd_HHMMSS_<name>` (extension is up to the caller) |

## Usage
Paths relative to this skill's directory.

```bash
bash scripts/io.sh inputs ../..
OUT="$(bash scripts/io.sh output ../.. summary).md"   # -> output/20260101_120000_summary.md
```

In application code mirror the same convention: `Path("input").rglob("*")`, and `datetime.now().strftime("%Y%m%d_%H%M%S")` in output file names.

## Rules
- Process input recursively; never assume a flat folder.
- Never overwrite earlier outputs; the timestamp makes names unique.
- `input/` and `output/` folders are tracked in Git, their content is not (`git-hygiene`).
