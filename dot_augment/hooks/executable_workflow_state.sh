#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
SessionStart hook: Check for existing workflow artifacts and suggest resumption.

Scans Basic Memory for recent artifacts (specs, plans, explorations) and injects
context about where the user left off in their workflow.
"""

from __future__ import annotations

import sys
from datetime import datetime, timedelta
from pathlib import Path

from augment_adapter import create_unified_context
from cchooks import SessionStartContext

# Basic Memory vault location
BASIC_MEMORY_VAULT = Path.home() / "basic-memory"
ARTIFACTS_DIR = BASIC_MEMORY_VAULT / "artifacts"

# How far back to look for recent artifacts
RECENT_DAYS = 7


def get_recent_artifacts() -> dict[str, list[dict]]:
    """Find recent artifacts in Basic Memory."""
    recent: dict[str, list[dict]] = {
        "specs": [],
        "plans": [],
        "explorations": [],
        "decisions": [],
    }

    cutoff = datetime.now() - timedelta(days=RECENT_DAYS)

    for artifact_type in recent.keys():
        artifact_dir = ARTIFACTS_DIR / artifact_type
        if not artifact_dir.exists():
            continue

        for f in artifact_dir.glob("*.md"):
            if f.name.startswith("TEMPLATE") or f.name.endswith("-template.md"):
                continue
            try:
                stat = f.stat()
                mtime = datetime.fromtimestamp(stat.st_mtime)
                if mtime > cutoff:
                    recent[artifact_type].append({
                        "name": f.stem,
                        "path": str(f.relative_to(BASIC_MEMORY_VAULT)),
                        "modified": mtime.isoformat(),
                    })
            except OSError:
                continue

    # Sort by modification time, most recent first
    for artifact_type in recent:
        recent[artifact_type].sort(key=lambda x: x["modified"], reverse=True)

    return recent


def infer_phase(artifacts: dict[str, list[dict]]) -> str:
    """Infer the likely current phase based on artifact state."""
    has_spec = bool(artifacts["specs"])
    has_plan = bool(artifacts["plans"])
    has_exploration = bool(artifacts["explorations"])

    if has_plan:
        return "EXECUTE"
    if has_spec:
        return "PLAN"
    if has_exploration:
        return "PLAN"
    return "EXPLORE"


def format_context(artifacts: dict[str, list[dict]]) -> str:
    """Format workflow context for injection."""
    lines = ["**Workflow Context (from Basic Memory)**", ""]

    total = sum(len(v) for v in artifacts.values())
    if total == 0:
        lines.append("No recent workflow artifacts found. Starting fresh.")
        lines.append("Suggested phase: EXPLORE")
        return "\n".join(lines)

    phase = infer_phase(artifacts)
    lines.append(f"Suggested phase: **{phase}**")
    lines.append("")

    for artifact_type, items in artifacts.items():
        if items:
            lines.append(f"**Recent {artifact_type}:**")
            for item in items[:3]:  # Show top 3
                lines.append(f"- [[{item['path']}]]")
            lines.append("")

    lines.append("Use `continue-conversation` skill to resume with full context.")
    return "\n".join(lines)


def format_visible_summary(artifacts: dict[str, list[dict]]) -> str:
    """Format a brief summary for terminal output."""
    total = sum(len(v) for v in artifacts.values())
    if total == 0:
        return "📋 Workflow: No recent artifacts. Phase: EXPLORE"

    phase = infer_phase(artifacts)
    counts = []
    for artifact_type, items in artifacts.items():
        if items:
            counts.append(f"{len(items)} {artifact_type}")

    return f"📋 Workflow: {', '.join(counts)} | Suggested phase: {phase}"


def main() -> None:
    """Inject workflow context at session start."""
    ctx = create_unified_context()

    if not isinstance(ctx, SessionStartContext):
        ctx.output.exit_success()
        return

    # Check if artifacts directory exists
    if not ARTIFACTS_DIR.exists():
        ctx.output.exit_success()
        return

    artifacts = get_recent_artifacts()
    total = sum(len(v) for v in artifacts.values())

    if total > 0:
        # Print visible summary to stderr for user
        print(format_visible_summary(artifacts), file=sys.stderr)

        # Inject full context for AI
        context = format_context(artifacts)
        ctx.output.add_context(context)
    else:
        ctx.output.exit_success()


if __name__ == "__main__":
    main()
