---
name: secure-config
description: Keep credentials, e-mails, usernames and URLs out of source code by using a .env file documented in .env.example, and scan a project for hard-coded secrets. Use when writing code that needs configuration or API keys, before commits or pushes, or when asked for a security or secrets check.
---

# secure-config

## Purpose
Implements `.bob/rules/security.md`: no hard-coded information; configuration comes from `.env`, documented by a committed `.env.example`.

## Procedure
1. Read configuration from the environment (`os.environ`, `process.env`, `${VAR}` in shell). Never inline values.
2. Add every variable to `.env.example` with a placeholder value and a one-line comment.
3. Make sure `.env` is ignored (skill `git-hygiene`).
4. Run the scanner and fix findings.

## Inputs
| Argument | Meaning |
|---|---|
| `project_dir` | Directory to scan (default `.`) |
| `--strict` | Also flag hard-coded `http(s)://` URLs in source files |

## Outputs
- Findings listed as `path:line:text` grouped by category (credential, token/private key, e-mail, URL).
- Warning if `.env.example` is missing.
- Exit `0` clean, `1` findings.
- Excluded: `.git node_modules .venv __pycache__ input output .bob .claude .run`, `.env.example`, lock files.
- Suppress a reviewed line by adding the word `nosecret` on that line.

## Usage
Paths are relative to this skill's directory.

```bash
bash scripts/scan_secrets.sh ../..           # scan the project
bash scripts/scan_secrets.sh --strict ../..  # also flag hard-coded URLs
```

`.env.example` pattern:

```dotenv
# LLM endpoint (llama.cpp OpenAI-compatible server)
LLM_BASE_URL=http://localhost:9931/v1
# API key, if the provider needs one
API_KEY=changeme
```

Also apply the Bob security guidance: https://internal.bob.ibm.com/docs/ide/security/bob-security-guidance
