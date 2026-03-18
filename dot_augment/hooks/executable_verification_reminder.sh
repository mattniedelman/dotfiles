#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
PostToolUse hook: Remind to verify after file modifications.

Injects context reminder after file edits to prevent premature success claims.
Particularly important for Sonnet which tends to claim success without verification.
"""

from __future__ import annotations

import json
from pathlib import Path

from augment_adapter import create_unified_context
from cchooks import PostToolUseContext

STATE_FILE = Path("/tmp/augment-edit-state.json")
EDIT_COUNT_THRESHOLD = 3


def load_state() -> dict:
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return {"edit_count": 0, "reminded": False}


def save_state(state: dict) -> None:
    STATE_FILE.write_text(json.dumps(state))


def main() -> None:
    ctx = create_unified_context()

    if not isinstance(ctx, PostToolUseContext):
        ctx.output.exit_success()
        return

    tool_name = ctx.tool_name
    edit_tools = {"str-replace-editor", "save-file"}

    if tool_name not in edit_tools:
        ctx.output.exit_success()
        return

    # Check if the tool execution was successful
    tool_response = ctx.tool_response or {}
    is_error = tool_response.get("error") is not None

    if is_error:
        ctx.output.exit_success()
        return

    state = load_state()
    state["edit_count"] = state.get("edit_count", 0) + 1
    save_state(state)

    if state["edit_count"] >= EDIT_COUNT_THRESHOLD and not state.get("reminded"):
        state["reminded"] = True
        save_state(state)
        ctx.output.add_context(
            "📋 Multiple files modified. Before claiming done:\n"
            "1. Run tests\n"
            "2. Run linters\n"
            "3. Show output in your response"
        )
    else:
        ctx.output.exit_success()


if __name__ == "__main__":
    main()

