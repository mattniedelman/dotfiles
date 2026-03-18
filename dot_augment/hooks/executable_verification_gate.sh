#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
Stop hook: Remind to run tests when code was modified.

Blocks completion if code was modified but tests weren't run.
Companion verification_tracker.sh updates state.

From: verification-before-completion skill + tdd-guard (19-repo analysis)
"""

from __future__ import annotations

import json
import os
from pathlib import Path

from augment_adapter import create_unified_context
from cchooks import StopContext

STATE_DIR = Path("/tmp/augment-verification-state")


def get_state_file(conv_id: str) -> Path:
    STATE_DIR.mkdir(exist_ok=True)
    return STATE_DIR / f"{conv_id}.json"


def main() -> None:
    ctx = create_unified_context()
    if not isinstance(ctx, StopContext):
        ctx.output.exit_success()
        return

    if ctx.stop_hook_active:
        ctx.output.allow()
        return

    conv_id = ctx.session_id or os.environ.get("AUGMENT_CONVERSATION_ID", "default")
    state_file = get_state_file(conv_id)

    if not state_file.exists():
        ctx.output.allow()
        return

    state = json.loads(state_file.read_text())
    code_modified = state.get("code_modified", False)
    tests_run = state.get("tests_run", False)
    test_files_modified = state.get("test_files_modified", False)

    if code_modified and not tests_run and not test_files_modified:
        ctx.output.prevent(
            "🧪 VERIFICATION CHECK: Code modified but tests not run.\n\n"
            "Before completing:\n"
            "1. Run relevant tests (pytest, npm test, etc.)\n"
            "2. Verify all tests pass\n\n"
            "If testing isn't applicable, explain why."
        )
        return

    ctx.output.allow()


if __name__ == "__main__":
    main()

