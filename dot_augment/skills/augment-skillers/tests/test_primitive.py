"""Tests for primitive classification."""

from datetime import UTC, datetime

from models import Observation, ObservationType, PrimitiveType, WeightedPattern
from primitive import classify_primitive


def _make_obs(obs_type: ObservationType, session_id: str = "s1") -> Observation:
    """Helper to create test observations."""
    return Observation(
        type=obs_type,
        content="test",
        session_id=session_id,
        exchange_index=0,
        timestamp=datetime.now(UTC),
    )


def _make_pattern_with_types(types: list[ObservationType]) -> WeightedPattern:
    """Create pattern with given observation types."""
    observations = [_make_obs(t, session_id=f"s{i}") for i, t in enumerate(types)]
    return WeightedPattern(
        theme="test",
        observations=observations,
        frequency=len(types),
        session_count=len(set(f"s{i}" for i in range(len(types)))),
        last_seen=datetime.now(UTC),
        weight=0.5,
    )


def test_workflow_dominant_suggests_hook() -> None:
    """Workflow ratio >= 0.5 should suggest hook."""
    types = [ObservationType.WORKFLOW] * 6 + [ObservationType.TASK] * 4
    pattern = _make_pattern_with_types(types)
    assert classify_primitive(pattern) == PrimitiveType.HOOK


def test_pain_dominant_suggests_agent() -> None:
    """Pain ratio >= 0.4 should suggest agent."""
    types = [ObservationType.PAIN] * 5 + [ObservationType.TASK] * 5
    pattern = _make_pattern_with_types(types)
    assert classify_primitive(pattern) == PrimitiveType.AGENT


def test_wish_counts_as_pain() -> None:
    """Wish observations should count toward pain ratio."""
    types = [ObservationType.WISH] * 4 + [ObservationType.TASK] * 6
    pattern = _make_pattern_with_types(types)
    assert classify_primitive(pattern) == PrimitiveType.AGENT


def test_task_dominant_suggests_skill() -> None:
    """Task ratio >= 0.3 should suggest skill."""
    types = [ObservationType.TASK] * 4 + [ObservationType.REPEAT] * 6
    pattern = _make_pattern_with_types(types)
    assert classify_primitive(pattern) == PrimitiveType.SKILL


def test_empty_pattern_defaults_to_skill() -> None:
    """Empty pattern should default to skill."""
    pattern = WeightedPattern(
        theme="test",
        observations=[],
        frequency=0,
        session_count=0,
        last_seen=datetime.now(UTC),
        weight=0.0,
    )
    assert classify_primitive(pattern) == PrimitiveType.SKILL


def test_mixed_defaults_to_skill() -> None:
    """Mixed observations below thresholds should default to skill."""
    types = [ObservationType.REPEAT] * 10
    pattern = _make_pattern_with_types(types)
    assert classify_primitive(pattern) == PrimitiveType.SKILL
