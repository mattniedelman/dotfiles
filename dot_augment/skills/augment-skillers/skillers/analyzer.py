"""Session analyzer - main entry point for skillers analysis."""

from __future__ import annotations

import sys
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import TYPE_CHECKING

# Add auglog to path
_AUGLOG_PATH = Path.home() / ".augment" / "skills" / "auglog-documenter" / "src"
sys.path.insert(0, str(_AUGLOG_PATH))

from auglog import Session, load_all  # noqa: E402
from classifier import classify_observation, extract_theme, is_noise  # noqa: E402
from ecosystem import check_existing_coverage, list_existing_skills  # noqa: E402
from models import Observation, Recommendation, WeightedPattern  # noqa: E402
from primitive import classify_primitive  # noqa: E402
from thresholds import meets_threshold  # noqa: E402
from weighting import calculate_weight  # noqa: E402

if TYPE_CHECKING:
    pass


def extract_observations(session: Session) -> list[Observation]:
    """Extract observations from a single session, filtering noise."""
    observations: list[Observation] = []

    for i, exchange in enumerate(session.chat_history):
        user_msg = exchange.exchange.request_message.strip()

        # Skip empty, very short, or noise messages
        if not user_msg or len(user_msg) < 5:
            pass  # Skip
        elif is_noise(user_msg):
            pass  # Skip noise
        else:
            obs_type = classify_observation(user_msg)
            timestamp = exchange.finished_at or session.created
            observations.append(
                Observation(
                    type=obs_type,
                    content=user_msg[:200],
                    session_id=session.session_id,
                    exchange_index=i,
                    timestamp=timestamp,
                )
            )

    return observations


def cluster_by_theme(observations: list[Observation]) -> dict[str, list[Observation]]:
    """Cluster observations by meaningful theme, skipping noise prefixes."""
    clusters: dict[str, list[Observation]] = {}

    for obs in observations:
        # Extract meaningful theme, skipping common question starters
        theme = extract_theme(obs.content)

        # Skip if no meaningful theme could be extracted
        if not theme:
            pass  # Skip
        else:
            if theme not in clusters:
                clusters[theme] = []
            clusters[theme].append(obs)

    return clusters


def analyze_sessions(days: int = 30) -> list[Recommendation]:
    """
    Analyze recent sessions and return recommendations.

    Args:
        days: Number of days to look back

    Returns:
        List of recommendations sorted by weight
    """
    # Load sessions
    sessions = load_all()
    cutoff = datetime.now(UTC) - timedelta(days=days)
    recent = [s for s in sessions if s.created > cutoff]

    # Extract all observations
    all_observations: list[Observation] = []
    for session in recent:
        all_observations.extend(extract_observations(session))

    # Cluster by theme
    clusters = cluster_by_theme(all_observations)

    # Build weighted patterns
    patterns: list[WeightedPattern] = []
    for theme, obs_list in clusters.items():
        # Skip empty themes (noise filtered out)
        if not theme:
            pass
        else:
            weight = calculate_weight(obs_list, theme=theme)
            pattern = WeightedPattern(
                theme=theme,
                observations=obs_list,
                frequency=len(obs_list),
                session_count=len(set(o.session_id for o in obs_list)),
                last_seen=max(o.timestamp for o in obs_list),
                weight=weight,
            )
            patterns.append(pattern)

    # Filter by thresholds
    qualified = [p for p in patterns if meets_threshold(p)]

    # Build recommendations
    existing_skills = list_existing_skills()
    recommendations: list[Recommendation] = []

    for pattern in qualified:
        primitive = classify_primitive(pattern)
        coverage = check_existing_coverage(pattern.theme, existing_skills)

        recommendations.append(
            Recommendation(
                primitive=primitive,
                theme=pattern.theme,
                reason=f"{pattern.frequency} occurrences across {pattern.session_count} sessions",
                evidence_count=pattern.frequency,
                session_count=pattern.session_count,
                weight=pattern.weight,
                existing_coverage=coverage,
            )
        )

    # Sort by weight descending
    recommendations.sort(key=lambda r: r.weight, reverse=True)

    return recommendations


def format_recommendations(recommendations: list[Recommendation]) -> str:
    """Format recommendations as markdown."""
    if not recommendations:
        return "No automation opportunities found (need more session data)."

    lines = ["## Skillers Recommendations\n"]

    for i, rec in enumerate(recommendations[:10], 1):
        status = f"✓ Covered by `{rec.existing_coverage}`" if rec.existing_coverage else "⚡ New"
        lines.append(f"### {i}. {rec.theme}")
        lines.append(f"**Type:** {rec.primitive.value} | **Weight:** {rec.weight:.2f} | {status}")
        lines.append(f"**Evidence:** {rec.reason}")
        lines.append("")

    return "\n".join(lines)


def get_session_stats(days: int = 30) -> dict[str, int | float]:
    """Get basic session statistics."""
    sessions = load_all()
    cutoff = datetime.now(UTC) - timedelta(days=days)
    recent = [s for s in sessions if s.created > cutoff]

    total_exchanges = sum(len(s.chat_history) for s in recent)

    return {
        "sessions": len(recent),
        "total_exchanges": total_exchanges,
        "avg_exchanges": total_exchanges / len(recent) if recent else 0,
    }
