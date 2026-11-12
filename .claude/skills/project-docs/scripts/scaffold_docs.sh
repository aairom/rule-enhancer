#!/usr/bin/env bash
# Scaffold README.md, Docs/Quickstart.md and Docs/Architecture.md without overwriting existing files.
# Usage: scaffold_docs.sh [--license "MIT"] [--name "My Project"] [project_dir]
set -euo pipefail

LICENSE_TYPE="MIT"; NAME=""
while [ $# -gt 0 ]; do
  case "$1" in
    --license) LICENSE_TYPE="${2:?--license needs a value}"; shift 2;;
    --name)    NAME="${2:?--name needs a value}"; shift 2;;
    *) break;;
  esac
done
DIR="${1:-.}"
[ -n "$NAME" ] || NAME="$(basename "$(cd "$DIR" && pwd)")"
mkdir -p "$DIR/Docs"

write_new() { # $1 path; content on stdin
  if [ -e "$1" ]; then echo "kept existing: ${1#"$DIR"/}"; cat >/dev/null
  else cat > "$1"; echo "created: ${1#"$DIR"/}"; fi
}

write_new "$DIR/README.md" <<EOF
# $NAME

One-paragraph description of what the project does.

## Architecture

\`\`\`mermaid
flowchart LR
    U[User] --> A[Application]
    A --> D[(Data / input)]
    A --> O[output]
\`\`\`

## Workflow

\`\`\`mermaid
sequenceDiagram
    participant U as User
    participant A as Application
    U->>A: Provide input
    A-->>U: Timestamped result in output/
\`\`\`

## Quick start

See [Docs/Quickstart.md](Docs/Quickstart.md) and [Docs/Architecture.md](Docs/Architecture.md).

## License

$LICENSE_TYPE
EOF

write_new "$DIR/Docs/Quickstart.md" <<EOF
# Quickstart

1. Copy \`.env.example\` to \`.env\` and fill in the values.
2. Start: \`scripts/start.sh\` (prints the URL).
3. Run the tests: see the project README.
4. Stop: \`scripts/stop.sh\`.
5. Clean up: \`scripts/cleanup.sh\`.
EOF

write_new "$DIR/Docs/Architecture.md" <<EOF
# Architecture

\`\`\`mermaid
flowchart TD
    subgraph Input
        I[input/ folder, read recursively]
    end
    subgraph App
        P[Processing]
        UI[Local UI]
    end
    subgraph Output
        R[output/ timestamped results]
    end
    I --> P --> R
    UI --> P
\`\`\`
EOF

# Ensure the license section exists in an existing README too.
if ! grep -qiE '^#{1,3} +licen[cs]e' "$DIR/README.md"; then
  printf '\n## License\n\n%s\n' "$LICENSE_TYPE" >> "$DIR/README.md"
  echo "updated: README.md (added License section)"
fi
