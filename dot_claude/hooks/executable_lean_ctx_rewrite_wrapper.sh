#!/usr/bin/env bash
# Wrapper around lean-ctx hook rewrite that passes through commands
# matching Claude Code's sandbox.excludedCommands so they aren't
# rewritten and can be correctly matched for sandbox bypass.

INPUT=$(cat)
CMD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)

# Check if the command starts with an excluded command
case "$CMD" in
    git\ *|git|bd\ *|bd)
        # Pass through -- no updatedInput means Claude Code uses the original command
        echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
        ;;
    *)
        # Delegate to lean-ctx for compression/rewriting
        echo "$INPUT" | /home/mattniedelman/.local/share/mise/shims/lean-ctx hook rewrite
        ;;
esac
