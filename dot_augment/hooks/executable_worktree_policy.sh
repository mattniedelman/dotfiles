#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
Script-policy for worktree-aware tool permissions.

Allows certain operations (package install/remove, file deletion) in worktrees,
but requires user confirmation in main checkout.

This script is used as a toolPermissions script-policy (not a hook).
- Exit 0: Allow the tool execution
- Exit non-zero: Deny the tool execution (prompts user)
- stdout: Message shown to user

Payload format from Augment:
{
  "tool-name": "launch-process" or "remove-files",
  "event-type": "tool-call",
  "details": { ... tool-specific data ... },
  "timestamp": "..."
}
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def is_in_worktree(path: str) -> bool:
    """Check if a path is inside a .worktrees/ directory."""
    resolved = Path(path).resolve()
    for parent in [resolved, *resolved.parents]:
        if parent.name == ".worktrees":
            return True
    return False


def main() -> None:
    payload = json.load(sys.stdin)
    tool_name = payload.get("tool-name", "")
    details = payload.get("details", {})

    if tool_name == "launch-process":
        # Check if cwd is in a worktree
        cwd = details.get("cwd", "")
        if cwd and is_in_worktree(cwd):
            sys.exit(0)  # Allow

        # In main checkout - show what's being done
        command = details.get("command", "<no command>")
        print(f"Package operation in main checkout (not a worktree).")
        print(f"Command: {command}")
        print()
        print("Approve to proceed, or deny to cancel.")
        sys.exit(1)

    elif tool_name == "remove-files":
        # Check if all files are in a worktree
        file_paths = details.get("file_paths", [])
        if not file_paths:
            sys.exit(0)  # No files to remove

        # Check each file path
        non_worktree_files = [f for f in file_paths if not is_in_worktree(f)]

        if not non_worktree_files:
            sys.exit(0)  # All files in worktrees, allow

        # Some files in main checkout
        print(f"Deleting files in main checkout (not a worktree):")
        for f in non_worktree_files[:5]:  # Show first 5
            print(f"  - {f}")
        if len(non_worktree_files) > 5:
            print(f"  ... and {len(non_worktree_files) - 5} more")
        print()
        print("Approve to proceed, or deny to cancel.")
        sys.exit(1)

    else:
        # Unknown tool, deny by default
        print(f"Unknown tool for worktree policy: {tool_name}")
        sys.exit(1)


if __name__ == "__main__":
    main()

