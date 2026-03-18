#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
PostToolUse hook: Track code modifications and test runs.

Companion to verification_gate.sh - updates state when:
- Code files are modified
- Test files are modified  
- Test commands are run

From: verification-before-completion skill (19-repo analysis)
"""

from __future__ import annotations

import json
import os
from pathlib import Path

from augment_adapter import create_unified_context
from cchooks import PostToolUseContext

STATE_DIR = Path("/tmp/augment-verification-state")

CODE_EXTENSIONS = {".py", ".ts", ".tsx", ".js", ".jsx", ".go", ".rs", ".java", ".rb", ".c", ".cpp", ".cs"}
TEST_PATTERNS = ["test_", "_test.", ".test.", "spec.", "_spec.", "conftest"]
TEST_COMMANDS = ["pytest", "python -m pytest", "npm test", "yarn test", "go test", "cargo test", "jest", "vitest"]


def get_state_file(conv_id: str) -> Path:
    STATE_DIR.mkdir(exist_ok=True)
    return STATE_DIR / f"{conv_id}.json"


def is_code_file(path: str) -> bool:
    return Path(path).suffix.lower() in CODE_EXTENSIONS


def is_test_file(path: str) -> bool:
    return any(p in path.lower() for p in TEST_PATTERNS)


def is_test_command(cmd: str) -> bool:
    return any(tc in cmd.lower() for tc in TEST_COMMANDS)


def main() -> None:
    ctx = create_unified_context()
    if not isinstance(ctx, PostToolUseContext):
        ctx.output.exit_success()
        return

    conv_id = ctx.session_id or os.environ.get("AUGMENT_CONVERSATION_ID", "default")
    state_file = get_state_file(conv_id)
    state = json.loads(state_file.read_text()) if state_file.exists() else {
        "code_modified": False, "test_files_modified": False, "tests_run": False
    }

    updated = False

    if ctx.tool_name in ("str-replace-editor", "save-file"):
        path = ctx.tool_input.get("path", "")
        if is_test_file(path):
            state["test_files_modified"] = True
            updated = True
        elif is_code_file(path):
            state["code_modified"] = True
            updated = True

    if ctx.tool_name == "launch-process":
        command = ctx.tool_input.get("command", "")
        if is_test_command(command):
            state["tests_run"] = True
            updated = True

    if updated:
        state_file.write_text(json.dumps(state))

    ctx.output.exit_success()


if __name__ == "__main__":
    main()

