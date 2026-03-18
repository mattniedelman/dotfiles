"""Tests for weighted knowledge formula."""

from datetime import UTC, datetime, timedelta

from models import Observation, ObservationType
from weighting import calculate_weight


def _make_obs(
    obs_type: ObservationType = ObservationType.TASK,
    session_id: str = "s1",
    timestamp: datetime | None = None,
) -> Observation:
    """Helper to create test observations."""
    return Observation(
        type=obs_type,
        content="test",
        session_id=session_id,
        exchange_index=0,
        timestamp=timestamp or datetime.now(UTC),
    )


def test_empty_observations_returns_zero() -> None:
    """Empty list should return 0."""
    assert calculate_weight([]) == 0.0


def test_weight_increases_with_frequency() -> None:
    """More observations should increase weight."""
    now = datetime.now(UTC)
    obs1 = [_make_obs(timestamp=now)]
    obs5 = [_make_obs(timestamp=now) for _ in range(5)]

    w1 = calculate_weight(obs1)
    w5 = calculate_weight(obs5)

    assert w5 > w1


def test_weight_increases_with_recency() -> None:
    """Recent observations should weigh more than old ones."""
    now = datetime.now(UTC)
    old = now - timedelta(days=60)

    recent_obs = [_make_obs(timestamp=now)]
    old_obs = [_make_obs(timestamp=old)]

    w_recent = calculate_weight(recent_obs)
    w_old = calculate_weight(old_obs)

    assert w_recent > w_old


def test_weight_increases_with_cross_session() -> None:
    """Multiple sessions should increase weight."""
    now = datetime.now(UTC)
    single_session = [_make_obs(session_id="s1", timestamp=now) for _ in range(3)]
    multi_session = [_make_obs(session_id=f"s{i}", timestamp=now) for i in range(3)]

    w_single = calculate_weight(single_session)
    w_multi = calculate_weight(multi_session)

    assert w_multi > w_single


def test_pain_boost_multiplier() -> None:
    """Pain/wish observations should get 1.5x boost."""
    now = datetime.now(UTC)
    task_obs = [_make_obs(obs_type=ObservationType.TASK, timestamp=now)]
    pain_obs = [_make_obs(obs_type=ObservationType.PAIN, timestamp=now)]

    w_task = calculate_weight(task_obs)
    w_pain = calculate_weight(pain_obs)

    # Pain should be exactly 1.5x task weight
    assert abs(w_pain - w_task * 1.5) < 0.001
