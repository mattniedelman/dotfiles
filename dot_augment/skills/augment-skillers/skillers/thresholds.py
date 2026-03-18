"""Evidence thresholds for automation recommendations."""

from models import WeightedPattern

# Minimum thresholds before suggesting automation
MIN_OCCURRENCES = 5
MIN_SESSIONS = 3
MIN_WEIGHT = 0.2


def meets_threshold(pattern: WeightedPattern) -> bool:
    """Check if a pattern meets evidence thresholds for recommendation."""
    return (
        pattern.frequency >= MIN_OCCURRENCES
        and pattern.session_count >= MIN_SESSIONS
        and pattern.weight >= MIN_WEIGHT
    )
