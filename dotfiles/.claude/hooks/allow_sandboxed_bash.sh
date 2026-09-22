#!/usr/bin/env bash
# PreToolUse hook: auto-allow bash commands that will run inside the sandbox.
# Works around the static-analyzer regression (anthropics/claude-code#43713)
# where shell expansions ($(), ${}, etc.) trigger permission prompts even
# when the command is sandboxed.
#
# Deny rules in settings.json still take precedence — the hook's "allow"
# decision is evaluated *before* deny/ask rules, so dangerous commands
# remain blocked.

input=$(cat)

# Only act on Bash tool calls
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
if [[ "$tool_name" != "Bash" ]]; then
	exit 0
fi

# If the command explicitly opts out of sandboxing, don't auto-allow
unsafe=$(echo "$input" | jq -r '.tool_input.dangerouslyDisableSandbox // false')
if [[ "$unsafe" == "true" ]]; then
	exit 0
fi

# Command will be sandboxed — allow it
echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
