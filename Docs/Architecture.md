# Architecture

## Source of truth and generated outputs

```mermaid
flowchart TD
    subgraph SRC["Source of truth (.bob)"]
        RULES[".bob/rules/*.md<br/>15 rules"]
        SKILLS[".bob/skills/&lt;name&gt;/<br/>SKILL.md + scripts + templates"]
    end
    subgraph GEN["Generated (Claude Code)"]
        CLAUDEMD["CLAUDE.md<br/>@.bob/rules/* imports"]
        CSK[".claude/skills/&lt;name&gt;/"]
    end
    SYNC[["scripts/sync_platforms.sh"]]
    RULES --> SYNC
    SKILLS --> SYNC
    SYNC --> CLAUDEMD
    SYNC --> CSK
    VAL[["scripts/validate_skills.sh"]] -.checks.-> SKILLS
    TEST[["tests/run_tests.sh"]] -.tests.-> SKILLS
    TEST -.tests.-> SYNC
    INST[["scripts/install.sh"]] --> TGT["Target project or ~/.bob, ~/.claude"]
    SRC --> INST
    GEN --> INST
```

## Skill composition

```mermaid
flowchart LR
    AUDIT["project-audit"] --> GIT["git-hygiene --check"]
    AUDIT --> SEC["secure-config"]
    AUDIT --> CON["container-images lint"]
    AUDIT --> STRUCT["structure checks"]
    GATE["test-gate"] --> RUN["pytest / unittest / npm / go / bats / tests/run_tests.sh"]
    DOCS["project-docs"]
    LIFE["project-lifecycle-scripts"]
    PY["python-env"]
    IO["io-folders"]
    LIFE -.->|"documents vars in .env.example"| SEC
    DOCS -.->|"creates README and License"| AUDIT
```

## Rule to skill mapping

```mermaid
flowchart LR
    R_GIT["git.md"] --> S_GIT["git-hygiene"]
    R_SEC["security.md"] --> S_SEC["secure-config"]
    R_AUTO["automation.md"] --> S_LIFE["project-lifecycle-scripts"]
    R_STRUCT["project-structure.md"] --> S_LIFE
    R_DOCS["documents.md"] --> S_DOCS["project-docs"]
    R_PY["python.md"] --> S_PY["python-env"]
    R_IO["input-output-folders.md"] --> S_IO["io-folders"]
    R_CONT["containers.md"] --> S_CONT["container-images"]
    R_TEST["unit-test.md"] --> S_TEST["test-gate"]
    R_AGENTS["AGENTS.md"] --> S_DOCS
    R_AGENTS --> S_TEST
```

## Design decisions
- **Rules say what, skills say how.** Rules stay tiny and always loaded; procedures load on demand, which reduces context cost.
- **Same `SKILL.md` format on both platforms** (frontmatter `name` + `description`, folder name equals `name`). No conversion needed, only a copy.
- **Rules reach Claude Code through `CLAUDE.md` `@` imports**, so there is no duplicated text to drift.
- **Skill scripts are plain Bash 3.2-compatible**, with exit codes, so they work on macOS and in any agent.
- **Idempotent and non-destructive**: scaffolders never overwrite existing files unless `--force` (project rule: update, don't recreate).
