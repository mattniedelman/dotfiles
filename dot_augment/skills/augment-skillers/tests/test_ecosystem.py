"""Tests for ecosystem checker."""

from ecosystem import check_existing_coverage, list_existing_skills


def test_finds_exact_skill_match() -> None:
    """Exact word match should return the skill."""
    skills = ["git-workflow", "python-development"]
    result = check_existing_coverage("git workflow", skills)
    assert result == "git-workflow"


def test_finds_partial_match() -> None:
    """Partial word match should return the skill."""
    skills = ["test-driven-development", "api-design"]
    result = check_existing_coverage("test patterns", skills)
    assert result == "test-driven-development"


def test_no_match_returns_none() -> None:
    """No matching words should return None."""
    skills = ["git-workflow", "python-development"]
    result = check_existing_coverage("kubernetes deployment", skills)
    assert result is None


def test_case_insensitive_matching() -> None:
    """Matching should be case insensitive."""
    skills = ["API-Design", "Python-Development"]
    result = check_existing_coverage("API patterns", skills)
    assert result == "API-Design"


def test_list_existing_skills_returns_list() -> None:
    """list_existing_skills should return a list (even if empty)."""
    result = list_existing_skills()
    assert isinstance(result, list)
    # Should find at least augment-skillers since we're building it
    # But don't assert specific skills exist since we're in test


def test_strips_hash_prefix_for_matching() -> None:
    """Slash command expansions with # prefix should match skills."""
    skills = ["deslop", "ralph-explore", "ralph-implement"]
    result = check_existing_coverage("# deslop assess", skills)
    assert result == "deslop"


def test_matches_skill_prefix() -> None:
    """First word should match skill prefix (e.g., 'ralph' matches 'ralph-*')."""
    skills = ["deslop", "ralph-explore", "ralph-implement"]
    result = check_existing_coverage("# ralph wiggum", skills)
    assert result is not None
    assert result.startswith("ralph")


def test_strips_slash_prefix() -> None:
    """Slash commands like '/deslop' should match 'deslop' skill."""
    skills = ["deslop", "git-workflow"]
    result = check_existing_coverage("/deslop", skills)
    assert result == "deslop"
