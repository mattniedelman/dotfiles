#!/usr/bin/env bash
# Bridge: RTK rewrite + dippy approval as separate concerns.
#
# Claude Code bug (anthropics/claude-code#15897, rtk-ai/rtk#893):
# When a hook returns permissionDecision AND updatedInput together,
# updatedInput is silently ignored.
#
# Workaround: RTK path returns only updatedInput (no permissionDecision).
# Bash must be in permissions.allow list, or user gets prompted.
# Non-RTK commands fall through to dippy for approval.

INPUT=$(cat)

# Try RTK rewrite
REWRITTEN_OUTPUT=$(echo "$INPUT" | "$(dirname "$0")/rtk-rewrite.sh" 2>/dev/null)
RTK_EXIT=$?

if [ $RTK_EXIT -eq 0 ] && [ -n "$REWRITTEN_OUTPUT" ]; then
  # Strip permissionDecision fields so updatedInput takes effect
  echo "$REWRITTEN_OUTPUT" | jq 'del(.hookSpecificOutput.permissionDecision, .hookSpecificOutput.permissionDecisionReason)'
  exit 0
fi

# No RTK equivalent -- fall through to dippy for approval
echo "$INPUT" | dippy 2>/dev/null
