#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.claude/hooks
"""
PreToolUse hook: Block write_note_basic-memory calls without a proper directory.

Prevents notes from being written to the root level of Basic Memory.
All notes must specify a directory parameter that is not empty or "/".
"""

from __future__ import annotations

from cchooks import create_context
from cchooks import PreToolUseContext


def main() -> None:
    ctx = create_context()

    if not isinstance(ctx, PreToolUseContext):
        ctx.output.exit_success()
        return

    tool_name = ctx.tool_name

    # Only handle mcp__basic-memory__write_note
    if tool_name != "mcp__basic-memory__write_note":
        ctx.output.allow()
        return

    tool_input = ctx.tool_input or {}
    directory = tool_input.get("directory", "")

    # Normalize: strip whitespace and trailing slashes
    directory = directory.strip().rstrip("/")

    # Check if directory is empty or root-level
    if not directory or directory == "":
        # Block the tool and tell agent to specify a directory
        ctx.output.deny(
            reason=(
                "Basic Memory write blocked: missing 'directory' parameter. "
                "Notes MUST be organized in subdirectories, not at root level. "
                "Use directories like: "
                "'knowledge/research/', 'artifacts/architecture/', 'artifacts/specs/', "
                "'knowledge/patterns/', 'journal/sessions/YYYY/MM/'. "
                "Retry write_note_basic-memory with a proper directory parameter."
            )
        )
        return

    # Directory is provided, allow the tool
    ctx.output.allow()


if __name__ == "__main__":
    main()
