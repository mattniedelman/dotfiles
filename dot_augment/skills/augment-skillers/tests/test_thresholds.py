"""Tests for evidence thresholds."""

from datetime import UTC, datetime

from models import WeightedPattern
from thresholds import meets_threshold


def _make_pattern(frequency: int, session_count: int, weight: float) -> WeightedPattern:
    """Helper to create test patterns."""
    return WeightedPattern(
        theme="test",
        observations=[],
        frequency=frequency,
        session_count=session_count,
        last_seen=datetime.now(UTC),
        weight=weight,
    )


def test_meets_all_thresholds() -> None:
    """Pattern meeting all thresholds should pass."""
    pattern = _make_pattern(frequency=10, session_count=5, weight=0.5)
    assert meets_threshold(pattern) is True


def test_fails_frequency_threshold() -> None:
    """Pattern with too few occurrences should fail."""
    pattern = _make_pattern(frequency=3, session_count=5, weight=0.5)
    assert meets_threshold(pattern) is False


def test_fails_session_threshold() -> None:
    """Pattern with too few sessions should fail."""
    pattern = _make_pattern(frequency=10, session_count=2, weight=0.5)
    assert meets_threshold(pattern) is False


def test_fails_weight_threshold() -> None:
    """Pattern with too low weight should fail."""
    pattern = _make_pattern(frequency=10, session_count=5, weight=0.1)
    assert meets_threshold(pattern) is False


def test_exact_threshold_values_pass() -> None:
    """Pattern at exactly threshold values should pass."""
    pattern = _make_pattern(frequency=5, session_count=3, weight=0.2)
    assert meets_threshold(pattern) is True
