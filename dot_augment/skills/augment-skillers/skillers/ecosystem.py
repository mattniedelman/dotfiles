"""Ecosystem awareness - check existing skills before recommending."""

from pathlib import Path

SKILLS_DIR = Path.home() / ".augment" / "skills"
AGENTS_DIR = Path.home() / ".augment" / "agents"


def list_existing_skills() -> list[str]:
    """List all existing skill names."""
    if not SKILLS_DIR.exists():
        return []
    return [d.name for d in SKILLS_DIR.iterdir() if d.is_dir() and (d / "SKILL.md").exists()]


def list_agents() -> list[str]:
    """List agent names from ~/.augment/agents/."""
    if not AGENTS_DIR.exists():
        return []
    return [f.stem for f in AGENTS_DIR.glob("*.md")]


def _normalize_theme(theme: str) -> str:
    """
    Normalize a theme for matching, handling slash command expansions.

    Handles patterns like:
    - "# ralph wiggum" → "ralph wiggum"
    - "# deslop assess" → "deslop assess"
    - "/deslop" → "deslop"
    """
    normalized = theme.strip()

    # Strip leading "# " (expanded slash command headers)
    if normalized.startswith("# "):
        normalized = normalized[2:]

    # Strip leading "/" (slash commands)
    if normalized.startswith("/"):
        normalized = normalized[1:]

    return normalized.lower()


# Explicit mappings for common commands to their covering skills
# These handle cases where word matching wouldn't naturally find the right skill
EXPLICIT_MAPPINGS: dict[str, str] = {
    "note": "knowledge-capture",
    "note quickly": "knowledge-capture",
    "research": "storm",
    "deep research": "storm",
    "walk me through": "step-through",
    "step through": "step-through",
    "one at a time": "step-through",
}


def check_existing_coverage(theme: str, skills: list[str] | None = None) -> str | None:
    """
    Check if an existing skill or subagent covers the given theme.

    Returns skill/subagent name if found, None otherwise.
    Handles slash command expansions (e.g., "# ralph wiggum" matches "ralph-*" subagents).
    """
    if skills is None:
        skills = list_existing_skills()

    # Also include agents in the search
    all_primitives = skills + list_agents()

    normalized = _normalize_theme(theme)

    # Check explicit mappings first
    for key, skill_name in EXPLICIT_MAPPINGS.items():
        if key in normalized:
            return skill_name

    theme_words = set(normalized.split())

    for primitive in all_primitives:
        primitive_words = set(primitive.replace("-", " ").lower().split())
        # Check for word overlap
        overlap = theme_words & primitive_words
        if overlap:
            return primitive

    # Second pass: check if first word of theme matches primitive prefix
    # This handles "ralph wiggum" matching "ralph-explore", "ralph-implement", etc.
    if theme_words:
        first_word = normalized.split()[0]
        for primitive in all_primitives:
            primitive_lower = primitive.lower()
            if primitive_lower.startswith(first_word) or first_word in primitive_lower.split("-"):
                return primitive

    return None
