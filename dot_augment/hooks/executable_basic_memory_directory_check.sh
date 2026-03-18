#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
PreToolUse hook: Block write_note_basic-memory calls without a proper directory.

Prevents notes from being written to the root level of Basic Memory.
All notes must specify a directory parameter that is not empty or "/".
"""

from __future__ import annotations

import json
import sys

# Read event data from stdin
event_data = json.load(sys.stdin)

tool_name = event_data.get("tool_name", "")

# Only handle write_note_basic-memory
if tool_name != "write_note_basic-memory":
    sys.exit(0)

tool_input = event_data.get("tool_input", {})
directory = tool_input.get("directory", "")

# Normalize: strip whitespace and trailing slashes
directory = directory.strip().rstrip("/")

# Check if directory is empty or root-level
if not directory or directory == "":
    # Block the tool and tell agent to specify a directory
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                "Basic Memory write blocked: missing 'directory' parameter. "
                "Notes MUST be organized in subdirectories, not at root level. "
                "Use directories like: "
                "'knowledge/research/', 'artifacts/architecture/', 'artifacts/specs/', "
                "'knowledge/patterns/', 'journal/sessions/YYYY/MM/'. "
                "Retry write_note_basic-memory with a proper directory parameter."
            ),
        }
    }
    print(json.dumps(output))
    sys.exit(0)

# Directory is provided, allow the tool
sys.exit(0)

