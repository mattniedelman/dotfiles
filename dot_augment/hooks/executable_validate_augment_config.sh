#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
# shellcheck disable=all
"""
PostToolUse hook: Validate Augment CLI config using agnix.

Runs agnix validator when config files are modified in ~/.augment/
to ensure configs comply with agent specification standards.
"""
# /// script
# requires-python = ">=3.11"
# dependencies = ["cchooks>=0.1.0"]
# ///

from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

from cchooks import PostToolUseContext

from augment_adapter import create_unified_context

AUGMENT_CONFIG_DIR = Path.home() / ".augment"
DEBUG = os.environ.get("VALIDATE_AUGMENT_CONFIG_DEBUG", "0") == "1"

# Patterns for Augment config files that should trigger validation
CONFIG_PATTERNS = [
    re.compile(r"\.augment/settings\.json$"),
    re.compile(r"\.augment/agents/.*\.md$"),
    re.compile(r"\.augment/commands/.*\.md$"),
    re.compile(r"\.augment/rules/.*\.md$"),
    re.compile(r"\.augment/skills/.*/SKILL\.md$"),
    re.compile(r"\.augment/hooks/.*\.(sh|py|json)$"),
    re.compile(r"\.augment/plugins/.*/(plugin|marketplace)\.json$"),
    re.compile(r"\.augment/plugins/.*/\.augment-plugin/.*\.json$"),
]


def debug(msg: str) -> None:
    """Print debug message to stderr if DEBUG is enabled."""
    if DEBUG:
        sys.stderr.write(f"[validate_augment_config] {msg}\n")


def _get_file_changes(ctx: PostToolUseContext) -> list[dict]:
    """Get file changes from either tool's format."""
    raw = ctx._input_data  # noqa: SLF001

    file_changes = raw.get("file_changes", [])
    if file_changes:
        return file_changes

    tool_response = ctx.tool_response
    if "content" in tool_response:
        return [tool_response]

    return []


def is_augment_config_file(path: str) -> bool:
    """Check if the path is an Augment config file."""
    return any(pattern.search(path) for pattern in CONFIG_PATTERNS)


def run_agnix() -> tuple[bool, str]:
    """Run agnix validator on ~/.augment/ directory."""
    cmd = ["npx", "agnix", str(AUGMENT_CONFIG_DIR)]
    debug(f"Running: {' '.join(cmd)}")
    try:
        result = subprocess.run(  # noqa: S603, S607
            cmd,
            capture_output=True,
            text=True,
            check=False,
            timeout=120,
            cwd=AUGMENT_CONFIG_DIR,
        )
        output = result.stdout + result.stderr
        debug(f"Exit code: {result.returncode}, Output: {output[:500]}")

        # agnix returns 0 for success, 1 for errors
        return result.returncode == 0, output.strip()
    except subprocess.TimeoutExpired:
        return False, "agnix validation timed out after 120s"
    except FileNotFoundError:
        return False, "npx not found - cannot run agnix validator"


def extract_error_summary(output: str) -> str:
    """Extract a concise error summary from agnix output."""
    lines = output.split("\n")
    errors = [line for line in lines if " error: " in line]
    summary_line = [line for line in lines if line.startswith("Found ")]

    if not errors:
        return output

    result_parts = []
    if len(errors) <= 5:
        result_parts.extend(errors)
    else:
        result_parts.extend(errors[:5])
        result_parts.append(f"... and {len(errors) - 5} more errors")

    if summary_line:
        result_parts.append("")
        result_parts.append(summary_line[0])

    return "\n".join(result_parts)


def main() -> None:
    """Validate Augment config when config files are modified."""
    debug("Hook invoked")
    ctx = create_unified_context()

    if not isinstance(ctx, PostToolUseContext):
        debug("Not a PostToolUseContext, exiting")
        sys.exit(0)

    file_changes = _get_file_changes(ctx)
    debug(f"File changes: {file_changes}")

    # Check if any changed files are Augment config files
    config_files_changed = []
    for change in file_changes:
        path = change.get("path", "")
        if path and is_augment_config_file(path):
            config_files_changed.append(path)
            debug(f"Config file changed: {path}")

    if not config_files_changed:
        debug("No Augment config files modified, exiting")
        ctx.output.exit_success()  # type: ignore[union-attr]

    # Run agnix validator
    success, output = run_agnix()

    if success:
        sys.stderr.write(
            f"✓ Augment config validation passed "
            f"(files: {', '.join(Path(f).name for f in config_files_changed)})\n"
        )
        ctx.output.exit_success()
    else:
        summary = extract_error_summary(output)
        context = (
            "**Augment config validation FAILED.**\n\n"
            "Fix the config file(s) to comply with agent specifications:\n\n"
            f"```\n{summary}\n```\n\n"
            "Run `npx agnix ~/.augment/` for full details."
        )
        debug(f"Validation failed: {summary}")
        ctx.output.add_context(context)


if __name__ == "__main__":
    main()

