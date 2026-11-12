---
name: container-images
description: Build small, Podman-compatible container images - multi-stage Dockerfile/Containerfile template and a policy linter (pinned tags, non-root, no secrets, Containerfile compatibility). Use when creating or reviewing a Dockerfile or Containerfile, containerizing an application, or optimizing image size. Podman Desktop and Podman engines are the local runtime.
---

# container-images

## Purpose
Implements `.bob/rules/containers.md`: Dockerfiles compatible with Containerfiles, smallest possible images, multi-stage builds so build tools never reach production.

## Inputs / Outputs
| Item | Detail |
|---|---|
| `templates/Containerfile` | Multi-stage Python template, non-root, `--no-cache-dir`; copy and adapt |
| `scripts/lint_containerfile.sh <file>` | Prints `FAIL:`/`WARN:` lines; exit `1` on violations |

Violations (FAIL): `:latest` base, final `USER root`, `SHELL`/`ONBUILD` (Docker-only), secret in `ENV`/`ARG`.
Advice (WARN): single stage, no `USER`, `pip install` without `--no-cache-dir`, `apt-get install` without list cleanup.

## Usage
Paths relative to this skill's directory.

```bash
cp templates/Containerfile ../../Containerfile
bash scripts/lint_containerfile.sh ../../Containerfile
podman build -t myapp -f Containerfile .      # Podman is the local engine
```

Size tips: slim/alpine/distroless runtime base, `.dockerignore`/`.containerignore` for `.git`, `.venv`, `node_modules`, `output`; combine `RUN` layers; copy only built artifacts to the final stage.
Remember to list pulled/built images in `PROJECT_IMAGES` so `cleanup-images.sh` (`project-lifecycle-scripts --images`) removes them at project end.
