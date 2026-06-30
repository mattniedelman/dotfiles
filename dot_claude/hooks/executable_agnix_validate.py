#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.claude/hooks
# /// script
# dependencies = ["cchooks"]
# ///
"""
PostToolUse hook (Edit|Write): Validate Claude Code config files with agnix.

Fires when a SKILL.md, AGENT.md, RULE.md, hook script, or settings file is
edited, runs `agnix validate` on it, and injects any violations as context
(non-blocking, mirroring auto_lint). For SKILL.md edits, also nudges to run the
workflow-skill-reviewer agent before deploying.

agnix exits 0 even when it reports warnings, so issues are detected by parsing
the output text, not the exit code.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

from cchooks import PostToolUseContext, create_context

# File patterns that agnix understands. Matched against the absolute path.
CONFIG_PATTERNS = (
    "SKILL.md",
    "AGENT.md",
    "RULE.md",
    "settings.json",
    "settings.local.json",
    ".mcp.json",
    "mcp.json",
)

# A hook script lives under a hooks/ dir and is .py or .sh -- agnix validates these.
HOOK_DIR_RE = re.compile(r"/hooks/[^/]+\.(py|sh)$")

# agnix summary line, e.g. "Found 0 errors, 2 warnings"
SUMMARY_RE = re.compile(r"Found\s+(\d+)\s+errors?,\s+(\d+)\s+warnings?")


def is_config_file(path: str) -> bool:
    """True if the edited file is a Claude Code config artifact agnix validates."""
    name = Path(path).name
    if name in CONFIG_PATTERNS:
        return True
    return bool(HOOK_DIR_RE.search(path))


def run_agnix(path: str) -> str:
    """Run agnix validate on a path; return output text, or '' on tool failure."""
    try:
        result = subprocess.run(  # noqa: S603
            ["agnix", "validate", path],  # noqa: S607
            capture_output=True,
            text=True,
            check=False,
            timeout=20,
        )
    except (OSError, subprocess.TimeoutExpired) as e:
        print(f"[agnix_validate] skipped: {e}", file=sys.stderr)  # noqa: T201
        return ""
    return result.stdout + result.stderr


def has_findings(output: str) -> bool:
    """True if agnix reported at least one error or warning."""
    m = SUMMARY_RE.search(output)
    if not m:
        return False
    errors, warnings = int(m.group(1)), int(m.group(2))
    return errors > 0 or warnings > 0


def main() -> None:
    """Validate edited config files with agnix and inject findings."""
    ctx = create_context()
    if not isinstance(ctx, PostToolUseContext):
        ctx.output.exit_success()
        return

    file_path = (ctx.tool_input or {}).get("file_path", "")
    if not file_path or not is_config_file(file_path):
        ctx.output.exit_success()
        return

    path = Path(file_path)
    if not path.is_file():
        ctx.output.exit_success()
        return

    parts: list[str] = []

    output = run_agnix(str(path))
    if output and has_findings(output):
        parts.append(
            "AGNIX VALIDATION issues in the config file you just edited. "
            "Fix ALL errors and warnings -- pre-existing issues are NOT exempt.\n\n"
            + output
        )

    # Skill-review nudge: agnix is structural; workflow-skill-reviewer judges quality.
    if path.name == "SKILL.md":
        parts.append(
            "You edited a SKILL.md. Before considering it done, run the "
            "`workflow-skill-reviewer` agent for a quality audit (structure, "
            "trigger accuracy, anti-patterns) -- agnix only checks structural rules."
        )

    if parts:
        parts.append(
            "AFTER handling the above: resume your original task exactly where you "
            "left off. Do NOT say 'Acknowledged' or 'Noted' -- act silently and continue."
        )
        ctx.output.add_context("\n\n".join(parts))
    else:
        ctx.output.exit_success()


if __name__ == "__main__":
    main()

# vim: set ft=python:
