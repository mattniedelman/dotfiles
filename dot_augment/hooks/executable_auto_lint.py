#!/usr/bin/env -S uv run --quiet --directory /home/mattniedelman/.augment/hooks
"""
PostToolUse hook: Auto-run linters on modified Python files.

Works with both Augment CLI and Claude Code via the unified adapter.
"""

from __future__ import annotations

import subprocess
from pathlib import Path

from augment_adapter import create_unified_context
from cchooks import PostToolUseContext

AST_GREP_CONFIG = Path.home() / ".config/ast-grep/sgconfig.yml"


def run_command(cmd: list[str]) -> tuple[int, str]:
    """Run a command and return exit code and output."""
    try:
        result = subprocess.run(  # noqa: S603
            cmd, capture_output=True, text=True, check=False
        )
        return result.returncode, result.stdout + result.stderr
    except FileNotFoundError:
        return -1, f"Command not found: {cmd[0]}"


def _get_file_changes(ctx: PostToolUseContext) -> list[dict]:
    """Get file changes from either tool's format."""
    raw = ctx._input_data  # noqa: SLF001

    # Augment format: file_changes array (preserved by adapter)
    file_changes = raw.get("file_changes", [])
    if file_changes:
        return file_changes

    # Claude Code format: tool_response may contain file info
    tool_response = ctx.tool_response
    if "content" in tool_response:
        return [tool_response]

    return []


def main() -> None:
    """Auto-run linters on modified Python files."""
    ctx = create_unified_context()

    if not isinstance(ctx, PostToolUseContext):
        ctx.output.exit_success()
        return

    file_changes = _get_file_changes(ctx)
    if not file_changes:
        ctx.output.exit_success()
        return

    # Collect Python files that were modified (not deleted)
    py_files = [
        change.get("path", "")
        for change in file_changes
        if change.get("changeType", "") != "delete"
        and change.get("path", "").endswith(".py")
        and Path(change.get("path", "")).is_file()
    ]

    if not py_files:
        ctx.output.exit_success()
        return

    lint_output: list[str] = []

    # Run ruff auto-fixes first (format and fixable lint issues)
    for file_path in py_files:
        run_command(["ruff", "format", file_path])
        run_command(["ruff", "check", "--fix", file_path])

    # Run ruff check on each file (report remaining unfixable issues)
    for file_path in py_files:
        exit_code, output = run_command(
            ["ruff", "check", "--output-format=concise", file_path]
        )
        if exit_code != 0 and output.strip():
            lint_output.append(f"ruff ({file_path}):\n{output}")

    # Run ast-grep on each file
    for file_path in py_files:
        exit_code, output = run_command(
            ["sg", "scan", "--config", str(AST_GREP_CONFIG), file_path]
        )
        if exit_code != 0 and output.strip():
            lint_output.append(f"ast-grep ({file_path}):\n{output}")

    if lint_output:
        context = (
            "LINT ERRORS detected in modified files. "
            "You MUST fix these before proceeding:\n\n"
        )
        context += "\n".join(lint_output)

        # Use cchooks API to add context
        ctx.output.add_context(context)
    else:
        ctx.output.exit_success()


if __name__ == "__main__":
    main()
