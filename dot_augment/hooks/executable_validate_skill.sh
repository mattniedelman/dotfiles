#!/usr/bin/env bash
# Validate skills when SKILL.md files are modified
# Runs skills-ref validator from agentskills/agentskills repository

set -euo pipefail

EVENT_DATA=$(cat)

# Extract file changes
FILE_CHANGES=$(echo "$EVENT_DATA" | jq -r '.file_changes // []')

# Check if any skill files were modified
SKILL_DIRS=()
while IFS= read -r path; do
  # Check if path is in a skills directory and contains SKILL.md
  if [[ "$path" =~ ^(.*/skills/[^/]+)/SKILL\.md$ ]] || [[ "$path" =~ ^(skills/[^/]+)/SKILL\.md$ ]]; then
    SKILL_DIR="${BASH_REMATCH[1]}"
    # Deduplicate
    if [[ ! " ${SKILL_DIRS[*]:-} " =~ \ ${SKILL_DIR}\  ]]; then
      SKILL_DIRS+=("$SKILL_DIR")
    fi
  fi
done < <(echo "$FILE_CHANGES" | jq -r '.[].path // empty')

# Exit early if no skill files were modified
if [[ ${#SKILL_DIRS[@]} -eq 0 ]]; then
  exit 0
fi

# Validate each modified skill
ERRORS=""
for skill_dir in "${SKILL_DIRS[@]}"; do
  # Handle relative paths - check workspace roots
  if [[ ! "$skill_dir" = /* ]]; then
    WORKSPACE=$(echo "$EVENT_DATA" | jq -r '.workspace_roots[0] // ""')
    if [[ -n "$WORKSPACE" ]]; then
      skill_dir="$WORKSPACE/$skill_dir"
    fi
  fi

  # Skip if directory doesn't exist
  if [[ ! -d "$skill_dir" ]]; then
    continue
  fi

  # Run validation
  OUTPUT=$(uvx --from "git+https://github.com/agentskills/agentskills#subdirectory=skills-ref" skills-ref validate "$skill_dir" 2>&1) || {
    ERRORS="${ERRORS}${OUTPUT}\n"
  }
done

# Report results
if [[ -n "$ERRORS" ]]; then
  # Output to agent as additional context
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "⚠️ Skill validation failed:\n${ERRORS}\nPlease fix the SKILL.md file to comply with agentskills.io specification."
  }
}
EOF
else
  # Success message to user
  echo "✓ Skill validation passed for: ${SKILL_DIRS[*]}" >&2
fi

exit 0
