"""Observation classifier using signal patterns."""

import re

from models import ObservationType

# Signal patterns for each observation type
PAIN_SIGNALS = [
    r"\b(broke|broken|failing|failed|error|bug|issue)\b",
    r"\b(again|keeps?|always)\b.*\b(fail|break|error)",
    r"\bwhy does\b",
    r"\bfrustrat",
]

WISH_SIGNALS = [
    r"\bi wish\b",
    r"\bwould be nice\b",
    r"\bshould (just|automatically)\b",
    r"\bif only\b",
]

WORKFLOW_SIGNALS = [
    r"\bfirst\b.*\bthen\b",
    r"\bstep \d+\b",
    r"\bafter\b.*\balways\b",
    r"\bbefore\b.*\bmust\b",
]

REPEAT_SIGNALS = [
    r"\b(run|check|verify|test|lint|build)\b",
    r"\bCI\b",
    r"\bstatus\b",
]

TASK_SIGNALS = [
    r"\b(refactor|implement|add|create|fix|update)\b",
    r"\b(feature|module|component|service)\b",
]

# Common conversational starters that don't indicate actionable patterns
STOPWORD_PREFIXES = {
    # Questions
    "what is",
    "what are",
    "what's",
    "whats",
    "what do",
    "what did",
    "what was",
    "what would",
    "is there",
    "are there",
    "can you",
    "could you",
    "would you",
    "do you",
    "did you",
    "how do",
    "how does",
    "how can",
    "how did",
    "where is",
    "where are",
    "why is",
    "why did",
    "when did",
    "which",
    # Requests
    "let's look",
    "lets look",
    "let's go",
    "lets go",
    "show me",
    "tell me",
    "give me",
    "get me",
    # Opinions/reactions
    "i think",
    "i dont think",
    "i don't think",
    "i dont want",
    "i don't want",
    "i want to",
    "i need to",
    "i'm not",
    "im not",
    "i am not",
    # Confirmations
    "ok",
    "okay",
    "yes",
    "no",
    "sure",
    "alright",
    "right",
    "got it",
    "sounds good",
    "looks good",
    # Pleasantries
    "thanks",
    "thank you",
    "please",
    "sorry",
    # Fillers
    "hmm",
    "hm",
    "ah",
    "oh",
    "um",
    "uh",
    "well",
    "so",
    "anyway",
    "actually",
}

# Patterns that suggest actionable automation opportunities
ACTIONABLE_PATTERNS = [
    r"^/\w+",  # Slash commands
    r"^#\s+\w+",  # Expanded skill headers
    r"\b(every time|each time|whenever)\b",  # Repetition indicators
    r"\b(automate|automation)\b",  # Explicit automation requests
    r"\b(skill|hook|agent)\b",  # Augment primitives
    r"\b(always have to|always need to)\b",  # Manual repetition pain
]


def _matches_any(text: str, patterns: list[str]) -> bool:
    """Check if text matches any of the given patterns."""
    return any(re.search(pattern, text) for pattern in patterns)


# Priority-ordered list of (patterns, observation_type) tuples
_SIGNAL_PRIORITY = [
    (PAIN_SIGNALS, ObservationType.PAIN),
    (WISH_SIGNALS, ObservationType.WISH),
    (WORKFLOW_SIGNALS, ObservationType.WORKFLOW),
    (TASK_SIGNALS, ObservationType.TASK),
    (REPEAT_SIGNALS, ObservationType.REPEAT),
]


def is_noise(text: str) -> bool:
    """
    Check if text is conversational noise rather than actionable content.

    Returns True if the text should be filtered out.
    """
    text_lower = text.lower().strip()

    # Very short messages are noise
    if len(text_lower) < 10:
        return True

    # Single word responses
    if " " not in text_lower:
        return True

    # Check for stopword prefixes
    for prefix in STOPWORD_PREFIXES:
        if text_lower.startswith(prefix):
            # Exception: if it also matches actionable patterns, keep it
            if _matches_any(text_lower, ACTIONABLE_PATTERNS):
                return False
            return True

    return False


# Hedging/filler phrases that indicate noise even mid-sentence
HEDGING_PHRASES = {
    "it seems like",
    "it looks like",
    "i guess",
    "i suppose",
    "maybe we",
    "perhaps we",
    "let's see",
    "lets see",
    "i wonder",
    "not sure",
    "im not sure",
    "i'm not sure",
}

# Patterns that indicate bracketed/project-specific noise
NOISE_PATTERNS = [
    r"^\[.*?\]",  # Bracketed prefixes like [gas town]
    r"^\(.*?\)",  # Parenthetical prefixes
    r"^@\w+",  # Mentions
    r"<-",  # Arrow notation (often log/debug output)
    r"->",  # Arrow notation
    r"^(\w+)\s+\1$",  # Repeated word (e.g., "research research")
]


def _is_theme_noise(theme: str) -> bool:
    """Check if an extracted theme is still noise."""
    theme_lower = theme.lower()

    # Hedging phrases
    if theme_lower in HEDGING_PHRASES:
        return True

    # Too short after extraction
    if len(theme_lower) < 5:
        return True

    # Bracketed/project-specific noise (use search for mid-string patterns)
    for pattern in NOISE_PATTERNS:
        if re.search(pattern, theme_lower):
            return True

    return False


def extract_theme(text: str) -> str:
    """
    Extract a meaningful theme from text, skipping noise words.

    Returns empty string if no meaningful theme can be extracted.
    """
    text_lower = text.lower().strip()

    # For slash commands and skill headers, use them directly (high signal)
    if text_lower.startswith("/") or text_lower.startswith("# "):
        words = text_lower.split()[:3]
        return " ".join(words)

    # Skip bracketed prefixes (project tags, etc.)
    text_clean = re.sub(r"^\[.*?\]\s*", "", text_lower)
    text_clean = re.sub(r"^\(.*?\)\s*", "", text_clean)

    # Skip common question starters to find the meaningful part
    for prefix in STOPWORD_PREFIXES:
        if text_clean.startswith(prefix):
            remainder = text_clean[len(prefix) :].strip()
            # Strip common follow-up words
            for word in ["the", "a", "an", "any", "some", "about", "for", "to", "of"]:
                if remainder.startswith(word + " "):
                    remainder = remainder[len(word) + 1 :]
            words = remainder.split()[:3]
            if words:
                theme = " ".join(words)
                if not _is_theme_noise(theme):
                    return theme
            return ""

    # Default: use first 3 words
    words = text_clean.split()[:3]
    theme = " ".join(words)

    # Final noise check
    if _is_theme_noise(theme):
        return ""

    return theme


def classify_observation(text: str) -> ObservationType:
    """Classify user text into an observation type."""
    text_lower = text.lower()

    for patterns, obs_type in _SIGNAL_PRIORITY:
        if _matches_any(text_lower, patterns):
            return obs_type

    return ObservationType.TASK  # Default
