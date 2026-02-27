#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
PostToolUse hook: Provide context from git MCP server logs when tool errors occur.

When Augment receives MCP schema validation errors (-32602), it doesn't see the actual
error message from the git MCP server. This hook reads recent log entries and extracts
the real error message to inject as additionalContext.
"""
# /// script
# requires-python = ">=3.11"
# ///

from __future__ import annotations

import json
import sys
from pathlib import Path

# Constants
LOG_FILE = Path.home() / ".local/state/git-mcp-server/logs/combined.log"
MAX_LOG_LINES = 50  # How many recent lines to search


def extract_recent_errors(tool_name: str, max_age_seconds: float = 30.0) -> list[str]:
    """Extract recent error messages from the git MCP server log.

    Args:
        tool_name: The tool name as seen by Augment (e.g., "git_status_git")
        max_age_seconds: Maximum age of log entries to consider (default 30s for latency)
    """
    if not LOG_FILE.exists():
        return []

    errors = []
    # Strip the _git suffix to get the server's tool name (git_status_git -> git_status)
    server_tool_name = tool_name.rsplit("_git", 1)[0] if tool_name.endswith("_git") else tool_name

    try:
        # Read recent lines (more efficient than reading whole file)
        with LOG_FILE.open("r") as f:
            # Seek to near end of file
            try:
                f.seek(0, 2)  # End of file
                file_size = f.tell()
                # Read last 100KB max
                read_size = min(file_size, 100 * 1024)
                f.seek(max(0, file_size - read_size))
                if file_size > read_size:
                    f.readline()  # Skip partial line
                lines = f.readlines()[-MAX_LOG_LINES:]
            except OSError:
                lines = []

        import time
        now = time.time()

        for line in reversed(lines):
            try:
                log_entry = json.loads(line.strip())
            except json.JSONDecodeError:
                continue

            # Check if this is an error for our tool
            level = log_entry.get("level", 0)
            logged_tool = log_entry.get("toolName", "")

            # level 50 = error, level 60 = fatal
            if level < 50:
                continue

            # Check if tool name matches (server logs use git_status, we get git_status_git)
            if logged_tool and logged_tool != server_tool_name:
                continue

            # Check timestamp - only recent errors
            timestamp = log_entry.get("time", 0)
            if timestamp:
                # time is in milliseconds
                age_seconds = (now * 1000 - timestamp) / 1000
                if age_seconds > max_age_seconds:
                    continue

            # Extract the error message - prefer originalMessage, fall back to msg
            # Skip generic "Tool execution failed" messages
            error_msg = log_entry.get("msg", "")
            original_msg = log_entry.get("errorData", {}).get("originalMessage", "")

            if original_msg and original_msg not in errors:
                errors.append(original_msg)
            elif error_msg and error_msg != "Tool execution failed" and error_msg not in errors:
                errors.append(error_msg)

            # Usually one unique error is enough
            if len(errors) >= 3:
                break

    except Exception:
        pass

    return errors


def main():
    # Read event data from stdin
    event_data = json.load(sys.stdin)

    tool_name = event_data.get("tool_name", "")
    tool_error = event_data.get("tool_error", "")

    # Only handle git MCP tools that have errors
    if not tool_name.endswith("_git"):
        sys.exit(0)

    if not tool_error:
        sys.exit(0)

    # Check if this looks like a schema validation error (the symptom we're fixing)
    schema_error_indicators = [
        "does not match",
        "output schema",
        "-32602",
        "required property",
        "must NOT have additional properties",
    ]

    is_schema_error = any(indicator in tool_error for indicator in schema_error_indicators)

    if not is_schema_error:
        # Not a schema error, the error message is probably already clear
        sys.exit(0)

    # Extract recent errors from the log
    errors = extract_recent_errors(tool_name)

    if not errors:
        # No recent errors found, suggest checking logs
        context = (
            f"The git MCP server returned a schema error, but no recent log entries were found. "
            f"Check logs at: {LOG_FILE}"
        )
    else:
        # Provide the actual error(s)
        unique_errors = list(dict.fromkeys(errors))  # Dedupe while preserving order
        context = (
            f"Git MCP server actual error(s):\n"
            + "\n".join(f"- {e}" for e in unique_errors)
            + "\n\nThese errors indicate incorrect tool invocation, NOT a server bug. "
            "Review the parameters being passed to the git MCP tool."
        )

    output = {
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "additionalContext": context,
        }
    }
    print(json.dumps(output))


if __name__ == "__main__":
    main()

