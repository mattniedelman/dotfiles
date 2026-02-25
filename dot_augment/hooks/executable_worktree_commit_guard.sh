#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
PreToolUse hook: Allow free commits in .worktrees/, require confirmation elsewhere.

AI can commit freely when working in an isolated worktree (.worktrees/ directory).
In the main checkout, commits still require explicit user authorization.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

# Read event data from stdin
event_data = json.load(sys.stdin)

tool_name = event_data.get("tool_name", "")

# Only handle git_commit_git
if tool_name != "git_commit_git":
    sys.exit(0)

# Get the working directory from conversation state
conversation_id = event_data.get("conversation_id", "unknown")
state_file = Path(f"/tmp/augment-git-state/{conversation_id}.json")

working_dir = None
if state_file.exists():
    try:
        state = json.loads(state_file.read_text())
        working_dir = state.get("working_dir")
    except (json.JSONDecodeError, OSError):
        pass

# If we can't determine the working directory, be safe and require confirmation
if not working_dir:
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": (
                "Cannot determine git working directory. "
                "Please confirm you want to commit."
            ),
        }
    }
    print(json.dumps(output))
    sys.exit(0)

# Check if the working directory is inside a .worktrees/ directory
working_path = Path(working_dir).resolve()

# Look for .worktrees in any parent of the working directory
is_in_worktree = False
for parent in [working_path, *working_path.parents]:
    if parent.name == ".worktrees":
        is_in_worktree = True
        break

if is_in_worktree:
    # In a worktree - allow commit without asking
    sys.exit(0)
else:
    # In main checkout - require confirmation
    tool_input = event_data.get("tool_input", {})
    commit_message = tool_input.get("message", "<no message>")

    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": (
                f"Committing to main checkout (not a worktree). "
                f'Message: "{commit_message}"\n\n'
                f"Confirm this commit?"
            ),
        }
    }
    print(json.dumps(output))
    sys.exit(0)

