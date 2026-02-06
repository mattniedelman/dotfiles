#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
SessionStart hook: Inject project context and remind to check basic-memory.

Works with both Augment CLI and Claude Code via the unified adapter.
"""

from __future__ import annotations

from pathlib import Path

from augment_adapter import create_unified_context
from cchooks import SessionStartContext


def main() -> None:
    """Inject project context at session start."""
    ctx = create_unified_context()

    if not isinstance(ctx, SessionStartContext):
        ctx.output.exit_success()
        return

    # Get workspace from Claude Code's project dir or Augment's workspace_roots
    workspace = ctx.claude_project_dir
    if not workspace:
        # Fall back to Augment's workspace_roots (preserved in transformed data)
        workspace_roots = ctx._input_data.get("workspace_roots", [])  # noqa: SLF001
        if workspace_roots:
            workspace = workspace_roots[0]
        else:
            workspace = ""

    if not workspace:
        ctx.output.exit_success()
        return

    project = Path(workspace).name

    context_message = f"""Project: {project}

Check basic-memory for prior context on this project:
- Use build_context or recent_activity to see what's been worked on
- Search for related notes before starting new work
- Continue from previous decisions and learnings"""

    # Use cchooks API - works for both tools
    ctx.output.add_context(context_message)


if __name__ == "__main__":
    main()
