---
name: project-docs
description: Create the mandatory project documents - README.md (with architecture and workflow Mermaid diagrams and a License section), Docs/Quickstart.md and Docs/Architecture.md (Mermaid flow). Use when starting a project, documenting a project, or when README, Quickstart, Architecture or license information is missing. Updates existing docs rather than recreating them.
---

# project-docs

## Purpose
Implements `.bob/rules/documents.md`, the "License in README" rule and "update existing documents, don't create new ones".

## Inputs
| Argument | Meaning |
|---|---|
| `--license TYPE` | Open-source license name written in README (default `MIT`) |
| `--name NAME` | Project title (default: folder name) |
| `project_dir` | Target project (default `.`) |

## Outputs
- `README.md` (root; only document allowed outside `Docs/`) with architecture + workflow Mermaid diagrams and `## License`.
- `Docs/Quickstart.md`, `Docs/Architecture.md` (Mermaid flowchart).
- Existing files are **never overwritten**; a missing License section is appended to an existing README.

## Usage
Paths relative to this skill's directory.

```bash
bash scripts/scaffold_docs.sh --license "Apache-2.0" --name "Rule Enhancer" ../..
```

After scaffolding, edit the generated diagrams so they describe the real components, then keep them current on every change.
