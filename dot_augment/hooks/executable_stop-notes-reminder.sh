#!/usr/bin/env bash
# Stop hook: Remind about notes if files were modified
# Requires includeConversationData: true in hook config
# Reads Stop event from stdin, outputs reminder if work was done

set -euo pipefail

EVENT=$(cat)

# Check if there were file changes in the agent's response
# agentCodeResponse contains the agent's last response with file_changes
CHANGES=$(echo "$EVENT" | jq -r '
  .agentCodeResponse.file_changes // [] | length
')

# Also check if there were any tool uses that modified files
TOOL_CHANGES=$(echo "$EVENT" | jq -r '
  [.conversationData[]? | select(.role == "assistant") | .tool_uses[]? | 
   select(.name | test("str-replace-editor|save-file|write_note|edit_note"))] | length
')

TOTAL=$((CHANGES + TOOL_CHANGES))

if [ "$TOTAL" -gt 0 ]; then
  cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "decision": "block",
    "additionalContext": "Session involved ${TOTAL} file/note operations.\n\nBefore ending, consider:\n- Should any decisions or learnings be captured in basic-memory?\n- Were there insights worth documenting for future sessions?\n- Did the work relate to any existing specs that should be updated?\n\nUse knowledge-capture skill or write_note if notes are warranted."
  }
}
EOF
else
  # No changes, let it pass through
  cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "Stop"
  }
}
EOF
fi

