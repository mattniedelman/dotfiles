#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
PreToolUse hook: Detect and block repetitive tool patterns (circuit breaker).

Tracks tool call signatures in a session-scoped state file.
Warns after 3 similar calls to the same tool with similar arguments.

From: Ralph, Pilot Shell patterns (19-repo analysis)
"""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path

from augment_adapter import create_unified_context
from cchooks import PreToolUseContext

STATE_DIR = Path("/tmp/augment-loop-state")
WARN_THRESHOLD = 2
STOP_THRESHOLD = 3

MONITORED_TOOLS = {"str-replace-editor", "save-file", "launch-process", "codebase-retrieval", "view"}

SIGNATURE_KEYS = {
    "str-replace-editor": ["path", "old_str_1"],
    "save-file": ["path"],
    "launch-process": ["command"],
    "codebase-retrieval": ["information_request"],
}


def get_state_file(conversation_id: str) -> Path:
    STATE_DIR.mkdir(exist_ok=True)
    return STATE_DIR / f"{conversation_id}.json"


def signature_hash(tool_name: str, tool_input: dict) -> str:
    keys = SIGNATURE_KEYS.get(tool_name, list(tool_input.keys())[:3])
    sig_parts = [tool_name]
    for key in keys:
        if key in tool_input:
            value = tool_input[key]
            if isinstance(value, str):
                value = value[:100].lower().strip()
            sig_parts.append(f"{key}={value}")
    return hashlib.md5(":".join(sig_parts).encode()).hexdigest()[:16]


def main() -> None:
    ctx = create_unified_context()
    if not isinstance(ctx, PreToolUseContext):
        ctx.output.exit_success()
        return

    if ctx.tool_name not in MONITORED_TOOLS:
        ctx.output.allow()
        return

    conv_id = ctx.session_id or os.environ.get("AUGMENT_CONVERSATION_ID", "default")
    state_file = get_state_file(conv_id)

    state = json.loads(state_file.read_text()) if state_file.exists() else {"calls": {}, "warned": []}
    sig = signature_hash(ctx.tool_name, ctx.tool_input)

    if sig in state.get("warned", []):
        ctx.output.allow()
        return

    state["calls"][sig] = state["calls"].get(sig, 0) + 1
    count = state["calls"][sig]

    state_file.write_text(json.dumps(state))

    if count >= STOP_THRESHOLD:
        state.setdefault("warned", []).append(sig)
        state_file.write_text(json.dumps(state))
        ctx.output.allow(
            reason=(
                f"🛑 LOOP DETECTED ({count}x): STOP and reassess.\n"
                f"Tool: {ctx.tool_name}\n\n"
                "Questions to consider:\n"
                "- Is my assumption about the file/code wrong?\n"
                "- Do I need to re-read the file to get current state?\n"
                "- Should I try a completely different approach?\n"
                "- Should I ask the user for help?\n\n"
                "State what's blocking you before proceeding."
            )
        )
    elif count >= WARN_THRESHOLD:
        ctx.output.allow(
            reason=(
                f"⚠️ Pattern repeated ({count}x). Pause and verify your approach.\n"
                f"Tool: {ctx.tool_name}\n"
                "If the next attempt also fails, STOP and reassess strategy."
            )
        )
    else:
        ctx.output.allow()


if __name__ == "__main__":
    main()

