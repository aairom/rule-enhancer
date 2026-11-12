# Quickstart

This project refactors the 15 rules in `.bob/rules/` (same filenames, backward compatible) and adds 9 reusable skills that work in both IBM Bob and Claude Code. Skills follow the Bob documentation and the Claude Code `SKILL.md` convention. It also ships a Bob-only [task auto-approval system](#configuring-task-auto-approval) (two hooks).

## Use in this repository
```bash
tests/run_tests.sh                 # all tests (expects: Passed: 122  Failed: 0)
node tests/policy.test.mjs         # approval policy decision table only (expects: all 64 pass)
scripts/validate_skills.sh         # skills valid for Bob and Claude Code
scripts/sync_platforms.sh --check  # generated Claude files up to date?
```

> **Test status:** 122 checks pass with 0 failures, run on macOS with Bash 3.2 and Node 24 only. The hook tests need Node. The Claude Code output has **not yet been tested in a live Claude Code session**.

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

## Configuring Task Auto-Approval

Bob-only, and Claude Code ignores it. Bob normally asks before each `execute_command`. The two hooks in `.bob/hooks/` answer the routine, read-only ones and log every decision. Overview and diagram: [README](../README.md#auto-approval-system).

**Requirements:** Node.js on the PATH (the hooks run as `node .bob/hooks/...`) and a Bob version that supports the `PermissionRequest` and `PermissionResolved` hook events. These two events are not in the public lifecycle-hooks reference I could check, so confirm them for your Bob version; the policy file's header cites Insiders 2.3+. Workspace hooks load only in a trusted folder.

### How the two hooks work together

1. Bob is about to ask for approval of an `execute_command` and sends `approval-policy.mjs` a `PermissionRequest` event (JSON on stdin: `cwd`, `tool_name`, `tool_input.command`).
2. The policy splits the command into segments and checks every one. If all pass, it prints an `allow` decision and Bob does not prompt. Otherwise it prints nothing and Bob shows the normal prompt. It never denies.
3. When the request is settled, by the policy or by you, Bob sends `audit-resolved.mjs` a `PermissionResolved` event, and one JSON line is appended to `.bob/audit/approvals.jsonl`.

### Step by step

1. **Check Node:** `node --version`.
2. **Check the hook registration** in `.bob/settings.json`. Enabled means these two entries are present:

   ```json
   {
     "hooks": {
       "PermissionRequest": [
         {
           "matcher": "^execute_command$",
           "hooks": [{ "type": "command", "command": "node .bob/hooks/approval-policy.mjs", "timeout": 10 }]
         }
       ],
       "PermissionResolved": [
         {
           "hooks": [{ "type": "command", "command": "node .bob/hooks/audit-resolved.mjs", "timeout": 10 }]
         }
       ]
     }
   }
   ```

3. **Disable it** by removing the `PermissionRequest` entry (Bob prompts for everything again). Keep `PermissionResolved` if you still want the audit log; remove it to stop logging. There is no on/off flag in the file.
4. **Define what is auto-approved** in `ALLOW_PREFIXES` at the top of `.bob/hooks/approval-policy.mjs`. The policy rules live in that file, not in `settings.json`. A prefix matches whole tokens, so `"npm test"` matches `npm test -- --watch` but `"npm t"` does not match `npm test`.
5. **Run the decision table** after every change: `node tests/policy.test.mjs`. Add a case for each prefix you add.
6. **Review the log:** `tail -5 .bob/audit/approvals.jsonl` (`ts`, `session`, `tool`, `decision`, `input`).

### Minimal working example

Auto-approve `npm run typecheck` and `uv run pytest`. In `.bob/hooks/approval-policy.mjs`:

```js
const ALLOW_PREFIXES = [
  // ...existing entries...
  "npm run typecheck", "uv run pytest"
];
```

In `tests/policy.test.mjs`, add to `cases`:

```js
["npm run typecheck", "allow"], ["uv run pytest -q", "allow"],
["uv run pytest > out.txt", "defer"]   // redirects still keep the prompt
```

Then `node tests/policy.test.mjs` should end with `all 67 pass`. Verify a single command by hand:

```bash
echo '{"hook_event_name":"PermissionRequest","tool_name":"execute_command","cwd":"'"$PWD"'","tool_input":{"command":"npm run typecheck"}}' \
  | node .bob/hooks/approval-policy.mjs
# prints {"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}; no output means "ask me"
```

### What is never auto-approved
Even if a prefix matches, a segment keeps the prompt when it contains a write or redirect (`>`, `tee`, `rm`, `touch`), network tools, `sudo`, `git push`, command or process substitution, an option that executes or writes (`-exec`, `--output`, `--ext-diff`, `--pre`), a credential or env path (`.env`, `.ssh`, `secrets`, `~/.bob`, `/etc`), or a glob, brace list or recursive search that could reach one. Commands over 400 characters or with more than 6 segments also keep the prompt. Tools that can run code are deliberately not allow-listed: `awk`, `jq`, bare `make`, bare `git branch`.

> The policy is a convenience filter, not a security boundary. Keep the list short and read-only. `.bob/audit/` is git-ignored because it stores full command text.

### Using it in another project
`install.sh` does not copy the hooks or `settings.json` (copying settings would overwrite the target's own). Copy `.bob/hooks/` by hand, merge the `hooks` block above into the target's `.bob/settings.json`, and add `.bob/audit/` to its `.gitignore` (`git-hygiene` does this).

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
| Bob still prompts for a command you expected to be auto-approved | Normal when any segment is not allow-listed or hits a never-auto-approve rule. Check with the one-line probe in [Configuring Task Auto-Approval](#configuring-task-auto-approval); no output means the policy deferred. Also check `node --version` and that the folder is trusted. |
| Auto-approval seems to do nothing | The hook command runs from the project root (`node .bob/hooks/...`); open Bob on that folder. Confirm `.bob/settings.json` is valid JSON. |
| The policy allowed something it should not have | Remove its prefix from `ALLOW_PREFIXES`, add a `"defer"` case to `tests/policy.test.mjs`, and rerun it. This happened once; see [README](../README.md#known-issues-and-fixes). |
| `--platform claude` also created `.bob/rules/` | Expected: `CLAUDE.md` imports each rule from there. |
| llama.cpp port 8080 vs 9931 | **Open.** Conflict in `.bob/rules/local-llm.md`; verify which is live and keep one. |

See [Optimization-Report.md](Optimization-Report.md) for the full change list and [Architecture.md](Architecture.md) for diagrams.
