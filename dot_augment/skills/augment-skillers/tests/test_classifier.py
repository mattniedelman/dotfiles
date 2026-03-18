"""Tests for observation classifier."""

import pytest
from classifier import classify_observation, extract_theme, is_noise
from models import ObservationType


@pytest.mark.parametrize(
    ("text", "expected"),
    [
        ("this broke again", ObservationType.PAIN),
        ("why does this keep failing", ObservationType.PAIN),
        ("the test is broken", ObservationType.PAIN),
        ("run the tests", ObservationType.REPEAT),
        ("check CI status", ObservationType.REPEAT),
        ("refactor the auth module", ObservationType.TASK),
        ("implement the login feature", ObservationType.TASK),
        ("I wish this was automatic", ObservationType.WISH),
        ("would be nice if it worked", ObservationType.WISH),
        ("first lint, then test, then commit", ObservationType.WORKFLOW),
        ("after editing, always run tests", ObservationType.WORKFLOW),
    ],
)
def test_classify_observation(text: str, expected: ObservationType) -> None:
    """Test observation classification for various inputs."""
    result = classify_observation(text)
    assert result == expected


def test_default_to_task() -> None:
    """Test that ambiguous text defaults to TASK."""
    result = classify_observation("hello world")
    assert result == ObservationType.TASK


# Tests for is_noise function
@pytest.mark.parametrize(
    ("text", "expected"),
    [
        ("what is the status", True),
        ("can you show me", True),
        ("ok", True),
        ("yes", True),
        ("thanks", True),
        ("let's look at this", True),
        ("# deslop assess", False),  # Slash command expansion
        ("/ralph explore codebase", False),  # Slash command (long enough)
        ("refactor the auth module", False),  # Actionable
        ("run the tests and check CI", False),  # Actionable
    ],
)
def test_is_noise(text: str, expected: bool) -> None:
    """Test noise detection."""
    result = is_noise(text)
    assert result == expected


# Tests for extract_theme function
@pytest.mark.parametrize(
    ("text", "expected"),
    [
        ("# deslop assess quality", "# deslop assess"),
        ("/ralph explore", "/ralph explore"),
        ("what is the status of CI", "status of ci"),
        ("show me the error logs", "error logs"),  # show me stripped, meaningful content kept
        ("refactor the auth module", "refactor the auth"),
    ],
)
def test_extract_theme(text: str, expected: str) -> None:
    """Test theme extraction."""
    result = extract_theme(text)
    assert result == expected
