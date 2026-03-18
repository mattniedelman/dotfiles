#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
PreToolUse hook: DAIC Plan Locking - remind about planning before code writes.

Soft gate: reminds about planning when writing code without explicit plan.
Tracks code writes per session and reminds periodically.

From: cc-sessions DAIC pattern (19-repo analysis)
"""

from __future__ import annotations

import json
import os
from pathlib import Path

from augment_adapter import create_unified_context
from cchooks import PreToolUseContext

STATE_DIR = Path("/tmp/augment-plan-state")

CODE_EXTENSIONS = {
    ".py", ".ts", ".tsx", ".js", ".jsx", ".go", ".rs", ".java",
    ".rb", ".php", ".c", ".cpp", ".h", ".hpp", ".cs", ".swift",
}

ALLOWED_PATTERNS = ["test_", "_test.", ".test.", "spec.", "conftest", ".md", ".json", ".yaml", ".yml"]


def get_state_file(conv_id: str) -> Path:
    STATE_DIR.mkdir(exist_ok=True)
    return STATE_DIR / f"{conv_id}.json"


def is_code_file(path: str) -> bool:
    path_lower = path.lower()
    if any(p in path_lower for p in ALLOWED_PATTERNS):
        return False
    return Path(path).suffix.lower() in CODE_EXTENSIONS


def main() -> None:
    ctx = create_unified_context()
    if not isinstance(ctx, PreToolUseContext):
        ctx.output.exit_success()
        return

    if ctx.tool_name not in ("str-replace-editor", "save-file"):
        ctx.output.allow()
        return

    path = ctx.tool_input.get("path", "")
    if not is_code_file(path):
        ctx.output.allow()
        return

    conv_id = ctx.session_id or os.environ.get("AUGMENT_CONVERSATION_ID", "default")
    state_file = get_state_file(conv_id)

    state = json.loads(state_file.read_text()) if state_file.exists() else {"approved": False, "writes": 0}

    if state.get("approved"):
        state["writes"] = state.get("writes", 0) + 1
        state_file.write_text(json.dumps(state))
        ctx.output.allow()
        return

    state["writes"] = state.get("writes", 0) + 1
    writes = state["writes"]
    state_file.write_text(json.dumps(state))

    if writes == 1:
        ctx.output.allow(
            reason=(
                "📋 PLAN REMINDER: Writing code without explicit plan.\n\n"
                "For complex changes: discuss approach → present plan → get confirmation.\n"
                "Say 'approved' or 'proceed' after presenting a plan.\n"
                "Proceeding with this write."
            )
        )
    elif writes % 5 == 0:
        ctx.output.allow(
            reason=(
                f"⚠️ PLAN CHECK: {writes} code writes without plan approval.\n"
                "Consider pausing to confirm this matches user intent."
            )
        )
    else:
        ctx.output.allow()


if __name__ == "__main__":
    main()

