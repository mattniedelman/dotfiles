#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "pydantic>=2.0",
#     "pydantic-settings>=2.0",
#     "plyvel>=1.5.0",
# ]
# ///
"""Skillers CLI - Mine sessions for automation opportunities."""

from __future__ import annotations

import sys
from pathlib import Path

# Add src to path for local imports
_SRC_PATH = Path(__file__).parent
sys.path.insert(0, str(_SRC_PATH))

# Import the module functions with absolute path since we added to sys.path
import analyzer  # noqa: E402
from pydantic import BaseModel, Field  # noqa: E402
from pydantic_settings import CliApp, CliSubCommand  # noqa: E402


class ShowCmd(BaseModel):
    """Show status and session statistics."""

    days: int = Field(default=30, description="Days to look back")


class CompactCmd(BaseModel):
    """Analyze transcripts and extract patterns."""

    days: int = Field(default=30, description="Days to look back")


class RecommendCmd(BaseModel):
    """Suggest skills, hooks, and agents to create."""

    days: int = Field(default=30, description="Days to look back")
    top: int = Field(default=10, description="Number of recommendations")


class SkillersCLI(BaseModel):
    """Skillers - Mine sessions for automation opportunities."""

    show: CliSubCommand[ShowCmd]
    compact: CliSubCommand[CompactCmd]
    recommend: CliSubCommand[RecommendCmd]


def _run_show(cmd: ShowCmd) -> int:
    """Execute show command."""
    stats = analyzer.get_session_stats(cmd.days)
    print("## Skillers Status")  # noqa: T201
    print("")  # noqa: T201
    print(f"**Sessions analyzed:** {stats['sessions']}")  # noqa: T201
    print(f"**Total exchanges:** {stats['total_exchanges']}")  # noqa: T201
    print(f"**Avg exchanges/session:** {stats['avg_exchanges']:.1f}")  # noqa: T201
    print("")  # noqa: T201
    print("Run `skillers recommend` for automation suggestions.")  # noqa: T201
    return 0


def _run_compact(cmd: CompactCmd) -> int:
    """Execute compact command."""
    recommendations = analyzer.analyze_sessions(cmd.days)
    print("## Analysis Complete")  # noqa: T201
    print("")  # noqa: T201
    print(f"Analyzed sessions from last {cmd.days} days")  # noqa: T201
    print(f"Found **{len(recommendations)}** patterns meeting evidence thresholds")  # noqa: T201
    return 0


def _run_recommend(cmd: RecommendCmd) -> int:
    """Execute recommend command."""
    recommendations = analyzer.analyze_sessions(cmd.days)
    output = analyzer.format_recommendations(recommendations[: cmd.top])
    print(output)  # noqa: T201
    return 0


def main() -> int:
    """CLI entry point."""
    cli = CliApp.run(SkillersCLI)

    if cli.show:
        return _run_show(cli.show)
    if cli.compact:
        return _run_compact(cli.compact)
    if cli.recommend:
        return _run_recommend(cli.recommend)

    return 0


if __name__ == "__main__":
    sys.exit(main())
