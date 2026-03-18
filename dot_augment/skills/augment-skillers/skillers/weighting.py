"""Weighted knowledge formula implementation."""

import math
from datetime import UTC, datetime

from models import Observation, ObservationType

# Formula constants
FREQUENCY_WEIGHT = 0.3
RECENCY_WEIGHT = 0.3
CROSS_SESSION_WEIGHT = 0.4
FREQUENCY_CAP = 20
RECENCY_HALF_LIFE_DAYS = 30

# Multipliers for different signal types
PAIN_BOOST = 1.5
SLASH_COMMAND_BOOST = 1.3  # High-signal: explicit skill/command invocation
CONCENTRATION_BOOST = 1.2  # Pattern used intensively in few sessions


def _is_high_signal_theme(theme: str) -> bool:
    """Check if theme indicates high-signal automation opportunity."""
    theme_lower = theme.lower()
    # Slash commands and skill headers are explicit automation invocations
    if theme_lower.startswith("/") or theme_lower.startswith("# "):
        return True
    return False


def calculate_weight(observations: list[Observation], theme: str = "") -> float:
    """
    Calculate weighted score for a set of observations.

    Formula: weight = (frequency * 0.3 + recency * 0.3 + crossSession * 0.4) * boosts

    Boosts:
    - Pain/wish types: 1.5x
    - Slash commands/skill headers: 1.3x
    - Concentrated usage (many occurrences in few sessions): 1.2x
    """
    if not observations:
        return 0.0

    # Frequency score (capped at 20)
    frequency = min(len(observations), FREQUENCY_CAP) / FREQUENCY_CAP

    # Recency score (exponential decay with 30-day half-life)
    now = datetime.now(UTC)
    most_recent = max(obs.timestamp for obs in observations)
    days_ago = (now - most_recent).total_seconds() / 86400  # Convert to days
    recency = math.exp(-days_ago * math.log(2) / RECENCY_HALF_LIFE_DAYS)

    # Cross-session score (unique sessions)
    unique_sessions = len(set(obs.session_id for obs in observations))
    cross_session = min(unique_sessions / 5, 1.0)  # Normalize to 5 sessions

    # Base weight
    base_weight = (
        frequency * FREQUENCY_WEIGHT
        + recency * RECENCY_WEIGHT
        + cross_session * CROSS_SESSION_WEIGHT
    )

    # Apply multipliers
    multiplier = 1.0

    # Pain boost for pain/wish types
    has_pain = any(obs.type in (ObservationType.PAIN, ObservationType.WISH) for obs in observations)
    if has_pain:
        multiplier *= PAIN_BOOST

    # High-signal theme boost
    if theme and _is_high_signal_theme(theme):
        multiplier *= SLASH_COMMAND_BOOST

    # Concentration boost: many occurrences in few sessions = intensive use
    # Ratio > 2 means avg more than 2 uses per session
    if unique_sessions > 0:
        concentration_ratio = len(observations) / unique_sessions
        if concentration_ratio >= 2.5:
            multiplier *= CONCENTRATION_BOOST

    return base_weight * multiplier
