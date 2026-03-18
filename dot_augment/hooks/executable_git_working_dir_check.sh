#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
PreToolUse hook: Ensure git_set_working_dir_git is called before other git MCP tools.

Tracks working dir state in a conversation-scoped temp file.
When a git tool is called without initialization, blocks and tells agent to initialize first.
"""

from __future__ import annotations

import json
import os
from pathlib import Path

from augment_adapter import create_unified_context
from cchooks import PreToolUseContext


def load_state(state_file: Path) -> dict:
    """Load conversation state."""
    if state_file.exists():
        try:
            return json.loads(state_file.read_text())
        except (json.JSONDecodeError, OSError):
            pass
    return {"working_dir_set": False, "working_dir": None}


def save_state(state_file: Path, state: dict) -> None:
    """Save conversation state."""
    state_file.write_text(json.dumps(state))


def main() -> None:
    ctx = create_unified_context()

    if not isinstance(ctx, PreToolUseContext):
        ctx.output.exit_success()
        return

    tool_name = ctx.tool_name

    # Only handle git MCP tools
    if not tool_name.endswith("_git"):
        ctx.output.allow()
        return

    # Get conversation ID and workspace roots from context
    conversation_id = ctx.session_id or os.environ.get("AUGMENT_CONVERSATION_ID", "unknown")
    raw_data = ctx._input_data  # noqa: SLF001
    workspace_roots = raw_data.get("workspace_roots", [])

    # State file tracks if working dir has been set for this conversation
    state_dir = Path("/tmp/augment-git-state")
    state_dir.mkdir(exist_ok=True)
    state_file = state_dir / f"{conversation_id}.json"

    state = load_state(state_file)

    # If this is git_set_working_dir_git, mark as initialized
    if tool_name == "git_set_working_dir_git":
        tool_input = ctx.tool_input or {}
        working_dir = tool_input.get("path", "")
        state["working_dir_set"] = True
        state["working_dir"] = working_dir
        save_state(state_file, state)
        ctx.output.allow()
        return

    # For other git tools, check if working dir is set
    if not state["working_dir_set"]:
        # Determine workspace path for suggestion
        workspace = workspace_roots[0] if workspace_roots else "the repository path"

        # Block the tool and tell agent to initialize first
        ctx.output.deny(
            reason=(
                f"Git MCP working directory not initialized. "
                f"Call git_set_working_dir_git with path '{workspace}' first, "
                f"then retry {tool_name}."
            )
        )
        return

    # Working dir is set, allow the tool
    ctx.output.allow()


if __name__ == "__main__":
    main()

