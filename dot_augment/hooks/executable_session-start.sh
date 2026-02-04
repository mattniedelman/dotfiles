#!/usr/bin/env bash
# SessionStart hook: Inject project context and remind to check basic-memory
# Reads SessionStart event from stdin, outputs additionalContext

set -euo pipefail

EVENT=$(cat)

# Extract first workspace root
WORKSPACE=$(echo "$EVENT" | jq -r '.workspace_roots[0] // ""')

if [ -z "$WORKSPACE" ]; then
  # No workspace, output empty response
  cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart"
  }
}
EOF
  exit 0
fi

# Extract project name from path
PROJECT=$(basename "$WORKSPACE")

# Output context injection
cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Project: ${PROJECT}\n\nCheck basic-memory for prior context on this project:\n- Use build_context or recent_activity to see what's been worked on\n- Search for related notes before starting new work\n- Continue from previous decisions and learnings"
  }
}
EOF

