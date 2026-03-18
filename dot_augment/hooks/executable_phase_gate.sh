#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
PreToolUse hook: Phase Gate Enforcement (explore → plan → implement).

Reminds about workflow phases when jumping to implementation.
Soft gate: injects context but doesn't block.

From: OMC, agentsys phase gates (19-repo analysis)
"""

from __future__ import annotations

import json
import os
from pathlib import Path

from augment_adapter import create_unified_context
from cchooks import PreToolUseContext

STATE_DIR = Path("/tmp/augment-phase-state")

CODE_EXTENSIONS = {".py", ".ts", ".tsx", ".js", ".jsx", ".go", ".rs", ".java", ".rb", ".c", ".cpp", ".cs"}
READ_ONLY_TOOLS = {"view", "codebase-retrieval", "web-search", "web-fetch", "list-processes", "read-process"}
PLAN_PATTERNS = ["plan", "spec", "design", "architecture", "proposal"]


def get_state_file(conv_id: str) -> Path:
    STATE_DIR.mkdir(exist_ok=True)
    return STATE_DIR / f"{conv_id}.json"


def is_code_file(path: str) -> bool:
    return Path(path).suffix.lower() in CODE_EXTENSIONS


def is_plan_file(path: str) -> bool:
    return any(p in path.lower() for p in PLAN_PATTERNS)


def main() -> None:
    ctx = create_unified_context()
    if not isinstance(ctx, PreToolUseContext):
        ctx.output.exit_success()
        return

    if ctx.tool_name in READ_ONLY_TOOLS:
        ctx.output.allow()
        return

    if ctx.tool_name.startswith("mcp:") and any(r in ctx.tool_name for r in ["read", "search", "list", "get"]):
        ctx.output.allow()
        return

    conv_id = ctx.session_id or os.environ.get("AUGMENT_CONVERSATION_ID", "default")
    state_file = get_state_file(conv_id)
    state = json.loads(state_file.read_text()) if state_file.exists() else {"explored": False, "planned": False}

    if ctx.tool_name in ("str-replace-editor", "save-file"):
        path = ctx.tool_input.get("path", "")

        if is_plan_file(path):
            state["planned"] = True
            state_file.write_text(json.dumps(state))
            ctx.output.allow()
            return

        if is_code_file(path) and not state.get("explored"):
            state["explored"] = True
            state_file.write_text(json.dumps(state))
            ctx.output.allow(
                reason=(
                    "📊 PHASE: Starting implementation.\n\n"
                    "For complex changes, consider:\n"
                    "1. Gather context with codebase-retrieval\n"
                    "2. Create a plan (writing-plans skill)\n"
                    "Proceeding, but a plan helps ensure alignment."
                )
            )
            return

    ctx.output.allow()


if __name__ == "__main__":
    main()

