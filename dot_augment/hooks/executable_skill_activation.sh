#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
# /// script
# requires-python = ">=3.11"
# dependencies = ["cchooks"]
# ///
"""
Skill Activation Hook - Declarative skill triggering

Triggers on: PreToolUse (any tool)
Purpose: Check user prompt against skill-rules.json and suggest/require skills

Based on diet103/claude-code-infrastructure-showcase pattern.
"""

import json
import os
import re
import sys
from pathlib import Path

from augment_adapter import create_unified_context
from cchooks import exit_success, output_json, PreToolUseContext

RULES_PATH = Path.home() / ".augment" / "skills" / "skill-rules.json"
STATE_DIR = Path("/tmp/augment-skill-state")


def load_rules() -> dict:
    """Load skill rules from JSON file."""
    if not RULES_PATH.exists():
        return {"skills": {}}
    return json.loads(RULES_PATH.read_text())


def get_session_state(session_id: str) -> dict:
    """Get session state for skill tracking."""
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    state_file = STATE_DIR / f"{session_id}.json"
    if state_file.exists():
        return json.loads(state_file.read_text())
    return {"skills_invoked": [], "skill_check_done": False}


def save_session_state(session_id: str, state: dict) -> None:
    """Save session state."""
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    state_file = STATE_DIR / f"{session_id}.json"
    state_file.write_text(json.dumps(state, indent=2))


def main():
    """Main hook logic."""
    ctx = create_unified_context()
    if not isinstance(ctx, PreToolUseContext):
        exit_success()
        return

    session_id = ctx.session_id or os.environ.get("AUGMENT_CONVERSATION_ID", "default")
    state = get_session_state(session_id)

    # Track when view tool is used on SKILL.md files (skill was read)
    tool_name = ctx.tool_name
    tool_input = ctx.tool_input or {}

    if tool_name == "view":
        path = tool_input.get("path", "")
        if "skills/" in path and path.endswith("SKILL.md"):
            skill_name = path.split("skills/")[-1].replace("/SKILL.md", "")
            if skill_name not in state["skills_invoked"]:
                state["skills_invoked"].append(skill_name)
                save_session_state(session_id, state)

    # Only check on first significant tool use per session
    if state.get("skill_check_done"):
        exit_success()
        return

    # Get recent prompt context (we don't have direct access, so use heuristics)
    # This is a limitation - we trigger on first code-modifying tool
    code_tools = ["str-replace-editor", "save-file", "launch-process"]
    if tool_name not in code_tools:
        exit_success()
        return

    # Mark that we've done the skill check
    state["skill_check_done"] = True
    save_session_state(session_id, state)

    # Check if any critical skills haven't been invoked
    rules = load_rules()
    critical_missing = []
    high_missing = []

    for skill_name, config in rules.get("skills", {}).items():
        if config.get("enforcement") == "block" and config.get("priority") == "critical":
            if skill_name not in state["skills_invoked"]:
                critical_missing.append(skill_name)
        elif config.get("priority") in ["high", "critical"]:
            if skill_name not in state["skills_invoked"]:
                high_missing.append(skill_name)

    # Generate reminder if missing critical skills
    if critical_missing or high_missing:
        msg = "🎯 SKILL ACTIVATION CHECK\n\n"

        if critical_missing:
            msg += "⚠️ CRITICAL SKILLS (read before proceeding):\n"
            for s in critical_missing[:3]:  # Limit to top 3
                msg += f"  → {s}\n"
            msg += "\n"

        if high_missing:
            msg += "📚 RECOMMENDED SKILLS:\n"
            for s in high_missing[:3]:
                msg += f"  → {s}\n"
            msg += "\n"

        msg += "ACTION: Use `view` tool on skills/<name>/SKILL.md before proceeding"

        # PreToolUse uses permissionDecisionReason
        output_json({
            "continue": True,
            "suppressOutput": False,
            "decision": "allow",
            "reason": msg,
        })
    else:
        exit_success()


if __name__ == "__main__":
    main()

