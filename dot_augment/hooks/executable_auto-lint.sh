#!/usr/bin/env bash
# PostToolUse hook: Auto-run linters on modified Python files
# Runs ruff and ast-grep, injects errors as context for the agent

set -euo pipefail

EVENT=$(cat)

# Extract file changes from the event
FILE_CHANGES=$(echo "$EVENT" | jq -r '.file_changes // []')
CHANGE_COUNT=$(echo "$FILE_CHANGES" | jq 'length')

if [ "$CHANGE_COUNT" -eq 0 ]; then
    exit 0
fi

# Collect Python files that were modified
PY_FILES=()
for i in $(seq 0 $((CHANGE_COUNT - 1))); do
    FILE_PATH=$(echo "$FILE_CHANGES" | jq -r ".[$i].path // \"\"")
    CHANGE_TYPE=$(echo "$FILE_CHANGES" | jq -r ".[$i].changeType // \"\"")
    
    # Skip deleted files
    if [ "$CHANGE_TYPE" = "delete" ]; then
        continue
    fi
    
    # Check if it's a Python file
    if [[ "$FILE_PATH" == *.py ]]; then
        # Verify file exists (it should, since it was just modified)
        if [ -f "$FILE_PATH" ]; then
            PY_FILES+=("$FILE_PATH")
        fi
    fi
done

if [ ${#PY_FILES[@]} -eq 0 ]; then
    exit 0
fi

LINT_OUTPUT=""
HAS_ERRORS=false

# Run ruff on each file
for FILE in "${PY_FILES[@]}"; do
    RUFF_OUTPUT=$(ruff check --output-format=concise "$FILE" 2>&1 || true)
    if [ -n "$RUFF_OUTPUT" ] && [ "$RUFF_OUTPUT" != "All checks passed!" ]; then
        LINT_OUTPUT="${LINT_OUTPUT}ruff ($FILE):\n${RUFF_OUTPUT}\n\n"
        HAS_ERRORS=true
    fi
done

# Run ast-grep on each file
for FILE in "${PY_FILES[@]}"; do
    SG_OUTPUT=$(sg scan "$FILE" 2>&1 || true)
    if [ -n "$SG_OUTPUT" ]; then
        LINT_OUTPUT="${LINT_OUTPUT}ast-grep ($FILE):\n${SG_OUTPUT}\n\n"
        HAS_ERRORS=true
    fi
done

if [ "$HAS_ERRORS" = true ]; then
    # Escape for JSON and output as additionalContext
    cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "LINT ERRORS detected in modified files. Fix these before proceeding:\n\n${LINT_OUTPUT}"
  }
}
EOF
fi

exit 0

