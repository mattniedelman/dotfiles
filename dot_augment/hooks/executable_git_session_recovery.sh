#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
PostToolUse hook: Detect git MCP server session loss and clear state for re-initialization.

When the git MCP server restarts (due to crash, ToolHive restart, etc.), it loses its
session working directory. This hook detects that condition and clears the conversation
state file so the PreToolUse hook will prompt for re-initialization.
"""

from __future__ import annotations

import os
from pathlib import Path

from augment_adapter import create_unified_context
from cchooks import PostToolUseContext

# Check if the output indicates session loss
SESSION_LOST_INDICATORS = [
    "No session working directory set",
    "Please specify a 'path' or use 'git_set_working_dir' first",
]


def main() -> None:
    ctx = create_unified_context()

    if not isinstance(ctx, PostToolUseContext):
        ctx.output.exit_success()
        return

    tool_name = ctx.tool_name

    # Only handle git MCP tools (except git_set_working_dir_git which sets state)
    if not tool_name.endswith("_git") or tool_name == "git_set_working_dir_git":
        ctx.output.exit_success()
        return

    # Check tool response for session loss indicators
    tool_response = ctx.tool_response or {}
    tool_output = str(tool_response.get("output", ""))

    session_lost = any(indicator in tool_output for indicator in SESSION_LOST_INDICATORS)

    if session_lost:
        # Get conversation ID from session or environment
        conversation_id = ctx.session_id or os.environ.get("AUGMENT_CONVERSATION_ID", "unknown")

        # Clear the state file so PreToolUse hook will block next git call
        state_dir = Path("/tmp/augment-git-state")
        state_file = state_dir / f"{conversation_id}.json"

        if state_file.exists():
            state_file.unlink()

        # Output a message to inform the agent
        ctx.output.add_context(
            "Git MCP server session was lost (server restarted). "
            "State cleared - next git operation will prompt for re-initialization."
        )
    else:
        ctx.output.exit_success()


if __name__ == "__main__":
    main()

