#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pydantic"]
# ///
"""
Sync instincts from local cache to Basic Memory.

Run this periodically or at session end to persist instincts.
Can be called manually: ~/.augment/hooks/instinct_sync.py

Uses Basic Memory MCP tools via the write_note function.

Note: Uses /tmp for local cache intentionally - ephemeral session buffer
that gets synced to Basic Memory for persistence.
"""
# ruff: noqa: T201
# ast-grep-ignore: no-print-statement, no-tmp-file-operations, no-module-level-variable

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Final

from pydantic import BaseModel


class ConfidenceThresholds:
    """Confidence score thresholds for instinct classification."""

    NEAR_CERTAIN: Final[float] = 0.9
    STRONG: Final[float] = 0.7
    MODERATE: Final[float] = 0.5


class InstinctData(BaseModel):
    """Validated instinct data structure."""

    id: str
    trigger: str
    domain: str
    confidence: float
    scope: str
    projects: list[str]
    evidence_count: int
    last_observed: str


def _get_cache_path() -> Path:
    """Get the instinct cache directory path."""
    return Path("/tmp/augment-instincts")  # noqa: S108


def confidence_label(conf: float) -> str:
    """Convert confidence score to human-readable label."""
    if conf >= ConfidenceThresholds.NEAR_CERTAIN:
        return "near-certain"
    if conf >= ConfidenceThresholds.STRONG:
        return "strong"
    if conf >= ConfidenceThresholds.MODERATE:
        return "moderate"
    return "tentative"


def format_instinct_note(data: InstinctData) -> str:
    """Format instinct data as Basic Memory note content."""
    projects_list = "\n".join(f"- {p}" for p in data.projects)
    conf_label = confidence_label(data.confidence)

    return f"""# Instinct: {data.id}

**Trigger:** {data.trigger}

**Domain:** {data.domain}

**Confidence:** {data.confidence:.2f} ({conf_label})

**Scope:** {data.scope}

**Evidence:** Observed {data.evidence_count} time(s) across \
{len(data.projects)} project(s)

## Projects

{projects_list}

## When to Apply

Apply this pattern {data.trigger}.

## Confidence History

- Started at 0.30 (tentative)
- Current: {data.confidence:.2f}
- Evidence count: {data.evidence_count}

## Observations

- [instinct] {data.trigger}
- [confidence] {conf_label} ({data.confidence:.2f})
- [scope] {data.scope}
- [last_observed] {data.last_observed}

## Relations

- categorized_as [[{data.domain}]]
"""


def get_pending_instincts() -> list[str]:
    """Get list of instinct IDs queued for sync."""
    queue_file = _get_cache_path() / "sync_queue.txt"
    if not queue_file.exists():
        return []

    ids = list(set(queue_file.read_text().strip().split("\n")))
    return [i for i in ids if i]


def load_instinct(instinct_id: str) -> InstinctData | None:
    """Load instinct data from cache."""
    cache_file = _get_cache_path() / f"{instinct_id}.json"
    if cache_file.exists():
        return InstinctData.model_validate_json(cache_file.read_text())
    return None


def clear_queue() -> None:
    """Clear the sync queue after successful sync."""
    queue_file = _get_cache_path() / "sync_queue.txt"
    if queue_file.exists():
        queue_file.unlink()


def main() -> None:
    """Sync pending instincts to Basic Memory."""
    pending = get_pending_instincts()

    if not pending:
        print("No instincts to sync")
        return

    print(f"Syncing {len(pending)} instinct(s) to Basic Memory...")

    synced = []
    for instinct_id in pending:
        data = load_instinct(instinct_id)
        if data is None:
            print(f"  ⚠️  {instinct_id}: not found in cache", file=sys.stderr)
        else:
            content = format_instinct_note(data)

            # Output JSON for write_note_basic-memory tool
            print(f"\n--- INSTINCT: {instinct_id} ---")
            print(
                json.dumps(
                    {
                        "title": f"Instinct: {instinct_id}",
                        "directory": "knowledge/instincts",
                        "content": content,
                        "tags": ["instinct", data.domain, data.scope],
                        "note_type": "instinct",
                    },
                    indent=2,
                )
            )

            synced.append(instinct_id)

    print(f"\n✅ Prepared {len(synced)} instinct(s) for sync")
    print("Use write_note_basic-memory with the JSON above to persist.")


if __name__ == "__main__":
    main()
