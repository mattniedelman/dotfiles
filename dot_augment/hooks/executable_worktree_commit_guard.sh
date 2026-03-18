#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
PreToolUse hook: Allow free commits in worktree directories, defer to toolPermissions elsewhere.

AI can commit freely when working in an isolated worktree:
- .worktrees/ directory (standard Augment worktrees)
- polecats/ directory (Gas Town polecat workers)

In the main checkout, the default toolPermission (ask-user) applies.

This hook only outputs "allow" for worktrees. For all other cases, it exits
silently and lets the toolPermissions default of "ask-user" handle it.
"""

from __future__ import annotations

import json
import os
from pathlib import Path

from augment_adapter import create_unified_context
from cchooks import PreToolUseContext

# Allowed worktree directory names
WORKTREE_DIRS = {".worktrees", "polecats"}


def main() -> None:
    ctx = create_unified_context()

    if not isinstance(ctx, PreToolUseContext):
        ctx.output.exit_success()
        return

    tool_name = ctx.tool_name

    # Only handle git_commit_git
    if tool_name != "git_commit_git":
        ctx.output.allow()
        return

    # Get the working directory from conversation state
    conversation_id = ctx.session_id or os.environ.get("AUGMENT_CONVERSATION_ID", "unknown")
    state_file = Path(f"/tmp/augment-git-state/{conversation_id}.json")

    working_dir = None
    if state_file.exists():
        try:
            state = json.loads(state_file.read_text())
            working_dir = state.get("working_dir")
        except (json.JSONDecodeError, OSError):
            pass

    # If we can't determine the working directory, let toolPermissions handle it (ask-user)
    if not working_dir:
        ctx.output.allow()
        return

    # Check if the working directory is inside an allowed worktree directory
    working_path = Path(working_dir).resolve()

    # Look for worktree directories in any parent of the working directory
    is_in_worktree = False
    for parent in [working_path, *working_path.parents]:
        if parent.name in WORKTREE_DIRS:
            is_in_worktree = True
            break

    if is_in_worktree:
        # In a worktree - explicitly allow commit without asking
        ctx.output.allow(reason="Committing in worktree - allowed without confirmation.")
        return

    # For main checkout, deny the commit - requires explicit user approval via Augment prompt
    tool_input = ctx.tool_input or {}
    commit_message = tool_input.get("message", "<no message>")

    ctx.output.deny(
        reason=(
            f"Committing to main checkout (not a worktree).\n"
            f'Message: "{commit_message}"\n\n'
            f"To commit, approve this tool call in Augment."
        )
    )


if __name__ == "__main__":
    main()

