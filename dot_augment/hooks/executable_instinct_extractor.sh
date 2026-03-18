#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
PostToolUse hook: Extract and evolve instincts from tool usage patterns.

Instincts are confidence-weighted micro-patterns stored in Basic Memory.
They evolve over time: reinforced on repeat observation, decayed on correction.

Based on everything-claude-code Continuous Learning v2 pattern.
"""

from __future__ import annotations

import json
import re
import subprocess
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

from augment_adapter import create_unified_context
from cchooks import PostToolUseContext

# =============================================================================
# DIFF-BASED PATTERN DETECTION (Option 3)
# Learns from what the agent CHANGES, not just what it writes
# =============================================================================

DIFF_PATTERNS = [
    # (old_pattern, new_pattern, instinct_id, trigger, domain)
    # If agent consistently replaces X with Y, learn that preference

    # Python modernization preferences
    (r"@dataclass", r"class \w+\(BaseModel\)", "prefer-pydantic-over-dataclass",
     "when creating data models", "python"),
    (r"from typing import Optional", r"(\w+) \| None", "prefer-union-syntax",
     "when typing optional values", "python"),
    (r"os\.path\.", r"Path\(", "prefer-pathlib-over-ospath",
     "when working with file paths", "python"),
    (r"print\(", r"logger\.", "prefer-logging-over-print",
     "when outputting information", "python"),
    (r"dict\[", r"TypedDict|BaseModel", "prefer-typed-structures",
     "when defining data structures", "python"),
    (r"\.format\(|% ", r"f\"", "prefer-fstrings",
     "when formatting strings", "python"),
    (r"json\.loads\(", r"\.model_validate", "prefer-pydantic-parsing",
     "when parsing JSON", "python"),

    # Testing preferences
    (r"unittest\.", r"pytest", "prefer-pytest-over-unittest",
     "when writing tests", "testing"),
    (r"mock\.|Mock\(|patch\(", r"# (fake|stub|real)", "prefer-fakes-over-mocks",
     "when testing dependencies", "testing"),

    # Error handling preferences
    (r"except Exception:", r"except \w+Error:", "prefer-specific-exceptions",
     "when handling errors", "python"),
    (r"assert ", r"if not .+:\s+raise", "prefer-explicit-validation",
     "when validating inputs", "python"),
]

# =============================================================================
# STATIC PATTERN EXTRACTORS (Original - kept for bootstrapping)
# =============================================================================

EXTRACTORS = [
    # Python patterns
    (r"from pydantic import|class \w+\(BaseModel\)", "prefer-pydantic", "when creating data models", "python"),
    (r"from pathlib import Path", "prefer-pathlib", "when working with file paths", "python"),
    (r"@dataclass", "uses-dataclass", "when creating data classes", "python"),
    (r"from typing import", "explicit-typing", "when defining function signatures", "python"),
    (r"async def \w+", "prefer-async", "when writing I/O functions", "python"),
    (r"raise \w+Error\(", "custom-exceptions", "when handling errors", "python"),

    # Testing patterns
    (r"def test_\w+.*:\s*\n\s*#\s*Arrange", "aaa-pattern", "when writing tests", "testing"),
    (r"@pytest\.fixture", "pytest-fixtures", "when setting up test data", "testing"),
    (r"assert \w+ ==", "direct-assertions", "when verifying test outcomes", "testing"),

    # Architecture patterns
    (r"class \w+Repository", "repository-pattern", "when accessing data", "architecture"),
    (r"class \w+Service", "service-layer", "when implementing business logic", "architecture"),
    (r"def __init__\(self,.*:\s*\w+", "dependency-injection", "when composing objects", "architecture"),

    # Git patterns
    (r"feat:|fix:|refactor:|docs:|test:|chore:", "conventional-commits", "when writing commit messages", "git"),

    # Documentation patterns
    (r'"""[\s\S]*?Args:', "google-docstrings", "when documenting functions", "docs"),
    (r"# TODO:|# FIXME:", "inline-todos", "when marking incomplete work", "docs"),
]


def extract_diff_patterns(old_content: str, new_content: str) -> list[tuple[str, str, str]]:
    """Extract patterns from what changed (diff-based learning)."""
    if not old_content or not new_content:
        return []

    matches = []
    for old_pat, new_pat, instinct_id, trigger, domain in DIFF_PATTERNS:
        # Check if old content had the pattern AND new content has the replacement
        old_match = re.search(old_pat, old_content)
        new_match = re.search(new_pat, new_content)

        if old_match and new_match:
            # Agent replaced old pattern with new pattern - learned preference!
            matches.append((instinct_id, trigger, domain))

    return matches


@dataclass
class Instinct:
    id: str
    trigger: str
    domain: str
    confidence: float
    scope: str  # "project" or "global"
    projects: list[str]
    evidence_count: int
    last_observed: str


def get_project_id(cwd: str | None = None) -> str:
    """Get current project identifier from git or cwd."""
    work_dir = Path(cwd) if cwd else Path.cwd()
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, timeout=5,
            cwd=work_dir
        )
        if result.returncode == 0:
            return Path(result.stdout.strip()).name
    except Exception:
        pass
    return work_dir.name


def extract_patterns(content: str) -> list[tuple[str, str, str]]:
    """Extract matching patterns from content."""
    matches = []
    for pattern, instinct_id, trigger, domain in EXTRACTORS:
        if re.search(pattern, content):
            matches.append((instinct_id, trigger, domain))
    return matches


# Local cache for instincts (synced to Basic Memory periodically)
INSTINCT_CACHE = Path("/tmp/augment-instincts")


def increment_edit_count(session_id: str) -> None:
    """Track edit count per session for reflection trigger."""
    INSTINCT_CACHE.mkdir(parents=True, exist_ok=True)
    counter_file = INSTINCT_CACHE / "edit_count.json"

    try:
        data = json.loads(counter_file.read_text()) if counter_file.exists() else {}
    except Exception:
        data = {}

    data[session_id] = data.get(session_id, 0) + 1
    counter_file.write_text(json.dumps(data))


def load_instinct(instinct_id: str) -> Instinct | None:
    """Load instinct from local cache."""
    cache_file = INSTINCT_CACHE / f"{instinct_id}.json"
    if cache_file.exists():
        try:
            data = json.loads(cache_file.read_text())
            return Instinct(**data)
        except Exception:
            pass
    return None


def save_instinct(instinct: Instinct) -> None:
    """Save instinct to local cache and queue for Basic Memory sync."""
    INSTINCT_CACHE.mkdir(parents=True, exist_ok=True)

    # Save to local cache
    cache_file = INSTINCT_CACHE / f"{instinct.id}.json"
    cache_file.write_text(json.dumps({
        "id": instinct.id,
        "trigger": instinct.trigger,
        "domain": instinct.domain,
        "confidence": instinct.confidence,
        "scope": instinct.scope,
        "projects": instinct.projects,
        "evidence_count": instinct.evidence_count,
        "last_observed": instinct.last_observed,
    }, indent=2))

    # Queue for Basic Memory sync (written by sync script)
    queue_file = INSTINCT_CACHE / "sync_queue.txt"
    with open(queue_file, "a") as f:
        f.write(f"{instinct.id}\n")


def confidence_label(conf: float) -> str:
    if conf >= 0.9: return "near-certain"
    if conf >= 0.7: return "strong"
    if conf >= 0.5: return "moderate"
    return "tentative"


def update_instinct(instinct: Instinct, project: str) -> Instinct:
    """Update instinct confidence and metadata."""
    # Increase confidence on repeated observation
    instinct.confidence = min(0.9, instinct.confidence + 0.05)
    instinct.evidence_count += 1
    instinct.last_observed = datetime.now().isoformat()[:10]

    # Track projects
    if project not in instinct.projects:
        instinct.projects.append(project)

    # Auto-promote to global if seen in 2+ projects with high confidence
    if instinct.confidence >= 0.8 and len(instinct.projects) >= 2:
        instinct.scope = "global"

    return instinct


def create_instinct(instinct_id: str, trigger: str, domain: str, project: str) -> Instinct:
    """Create new instinct with initial confidence."""
    return Instinct(
        id=instinct_id,
        trigger=trigger,
        domain=domain,
        confidence=0.3,  # Start tentative
        scope="project",
        projects=[project],
        evidence_count=1,
        last_observed=datetime.now().isoformat()[:10],
    )


def main() -> None:
    """Main hook logic."""
    ctx = create_unified_context()

    if not isinstance(ctx, PostToolUseContext):
        ctx.output.exit_success()
        return

    # Only extract from code-writing tools
    tool_name = ctx.tool_name
    if tool_name not in ["str-replace-editor", "save-file"]:
        ctx.output.exit_success()
        return

    tool_input = ctx.tool_input or {}

    # Get content being written (and old content for diff-based learning)
    new_content = ""
    old_content = ""

    if tool_name == "str-replace-editor":
        # Collect all old_str_N and new_str_N values
        for key, value in tool_input.items():
            if key.startswith("new_str_") and isinstance(value, str):
                new_content += value + "\n"
            if key.startswith("old_str_") and isinstance(value, str):
                old_content += value + "\n"
    elif tool_name == "save-file":
        new_content = tool_input.get("file_content", "")
        # save-file doesn't have old content

    if not new_content:
        ctx.output.exit_success()
        return

    # Extract patterns from new content (static patterns)
    patterns = extract_patterns(new_content)

    # Extract patterns from what CHANGED (diff-based learning) - higher signal!
    diff_patterns = extract_diff_patterns(old_content, new_content)

    # Combine, prioritizing diff patterns (they indicate actual preferences)
    all_patterns = diff_patterns + patterns

    # Track edit count for reflection trigger
    session_id = ctx.session_id or "default"
    increment_edit_count(session_id)

    if not all_patterns:
        ctx.output.exit_success()
        return

    # Get project from context cwd or file path
    cwd = getattr(ctx, "cwd", None)
    project = get_project_id(cwd)
    updated_instincts = []

    for instinct_id, trigger, domain in all_patterns:
        existing = load_instinct(instinct_id)

        if existing:
            instinct = update_instinct(existing, project)
        else:
            instinct = create_instinct(instinct_id, trigger, domain, project)

        save_instinct(instinct)
        updated_instincts.append(instinct)

    # Report what was learned (context injection)
    if updated_instincts:
        msg = "📚 INSTINCTS OBSERVED:\n"
        for inst in updated_instincts:
            status = "↑" if inst.evidence_count > 1 else "NEW"
            msg += f"  {status} {inst.id} ({inst.confidence:.2f})\n"

        ctx.output.add_context(msg)
    else:
        ctx.output.exit_success()


if __name__ == "__main__":
    main()

