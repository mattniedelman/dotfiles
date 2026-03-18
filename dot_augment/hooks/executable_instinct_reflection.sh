#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
Stop hook: Prompt agent to reflect on patterns used during session.

This enables LLM-assisted instinct learning - the agent identifies
patterns it used, which are then captured as instincts.

Based on everything-claude-code Continuous Learning v2 pattern.

Works with both Augment CLI and Claude Code via the unified adapter.
For Augment: requires includeConversationData: true in hook config.
"""
# ruff: noqa: T201
# ast-grep-ignore: no-print-statement

import json
from pathlib import Path

from augment_adapter import create_unified_context
from cchooks import StopContext

# Minimum edits to trigger reflection (avoid noise on tiny sessions)
MIN_EDITS_FOR_REFLECTION = 3

# Cache to track edit count per session
EDIT_COUNTER = Path("/tmp/augment-instincts/edit_count.json")  # noqa: S108


def get_edit_count(session_id: str) -> int:
    """Get number of code edits in this session."""
    if not EDIT_COUNTER.exists():
        return 0
    try:
        data = json.loads(EDIT_COUNTER.read_text())
        return data.get(session_id, 0)
    except Exception:
        return 0


def main() -> None:
    """Prompt reflection if session had significant edits."""
    ctx = create_unified_context()

    if not isinstance(ctx, StopContext):
        ctx.output.exit_success()
        return

    # Don't re-prompt if already continuing from a stop hook
    if ctx.stop_hook_active:
        ctx.output.allow()
        return

    session_id = ctx.session_id or "default"
    edit_count = get_edit_count(session_id)

    # Only prompt reflection for meaningful sessions
    if edit_count < MIN_EDITS_FOR_REFLECTION:
        ctx.output.allow()
        return

    # Check if we already have instincts queued (extraction already happened)
    queue_file = Path("/tmp/augment-instincts/sync_queue.txt")  # noqa: S108
    has_pending = queue_file.exists() and queue_file.read_text().strip()

    reflection_prompt = """📝 **SESSION REFLECTION - Pattern Learning**

This session included {edit_count} code edits. Before ending, consider:

1. **What patterns did you use consistently?**
   - Libraries/frameworks preferred (e.g., Pydantic over dataclass)
   - Coding conventions (e.g., type hints, docstring style)
   - Architecture patterns (e.g., repository pattern, dependency injection)

2. **What transformations did you make?**
   - Modernizations (e.g., os.path → pathlib)
   - Style changes (e.g., print → logging)
   - Structural improvements

3. **Capture as instincts** using write_note_basic-memory:
   ```
   Title: Instinct: <pattern-name>
   Directory: knowledge/instincts
   Tags: instinct, <domain>, project

   Content should include:
   - Trigger: when to apply
   - Domain: python/testing/architecture/etc
   - Rationale: why this pattern
   ```

{pending_note}""".format(
        edit_count=edit_count,
        pending_note=(
            "\n⚡ Note: Some instincts were auto-extracted. "
            "Run `~/.augment/hooks/instinct_sync.py` to sync them."
            if has_pending
            else ""
        ),
    )

    # Use cchooks API to prevent stopping and prompt for reflection
    ctx.output.prevent(reflection_prompt)


if __name__ == "__main__":
    main()

