#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
PostToolUse hook: Track plan approval phrases in ask-user responses.

Companion to plan_gate.sh - monitors for approval trigger phrases
and updates the plan approval state.

From: cc-sessions DAIC pattern (19-repo analysis)
"""

from __future__ import annotations

import json
import os
from pathlib import Path

from augment_adapter import create_unified_context
from cchooks import PostToolUseContext

STATE_DIR = Path("/tmp/augment-plan-state")

APPROVAL_PHRASES = [
    "approved", "lgtm", "looks good", "proceed", "go ahead",
    "do it", "implement", "ship it", "sounds good", "yes",
]


def get_state_file(conv_id: str) -> Path:
    STATE_DIR.mkdir(exist_ok=True)
    return STATE_DIR / f"{conv_id}.json"


def contains_approval(text: str) -> bool:
    return any(p in text.lower() for p in APPROVAL_PHRASES)


def main() -> None:
    ctx = create_unified_context()
    if not isinstance(ctx, PostToolUseContext):
        ctx.output.exit_success()
        return

    if ctx.tool_name != "ask-user":
        ctx.output.exit_success()
        return

    response = ctx.tool_response
    answer = ""
    if isinstance(response, dict):
        answer = response.get("answer", "") or response.get("response", "")
    elif isinstance(response, str):
        answer = response

    if not answer:
        ctx.output.exit_success()
        return

    if contains_approval(answer):
        conv_id = ctx.session_id or os.environ.get("AUGMENT_CONVERSATION_ID", "default")
        state_file = get_state_file(conv_id)
        state = json.loads(state_file.read_text()) if state_file.exists() else {}
        state["approved"] = True
        state_file.write_text(json.dumps(state))
        ctx.output.add_context("✅ PLAN APPROVED: Proceeding with implementation.")
    else:
        ctx.output.exit_success()


if __name__ == "__main__":
    main()

