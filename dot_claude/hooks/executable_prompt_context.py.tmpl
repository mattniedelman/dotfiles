#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.claude/hooks
# /// script
# dependencies = ["cchooks"]
# ///
"""
UserPromptSubmit hook: Inject relevant Basic Memory context for the first prompt.

Searches Basic Memory with keywords from the user's prompt and injects
matching notes as context before Claude responds. Only fires on the first
message of each session to avoid per-prompt overhead.
"""

from __future__ import annotations

import contextlib
import json
import re
import subprocess
from pathlib import Path
from typing import cast

from cchooks import UserPromptSubmitContext, create_context

LOG_FILE = Path.home() / ".claude" / "hooks" / "logs" / "prompt_context.log"

STOP_WORDS: frozenset[str] = frozenset(
    {
        "a",
        "an",
        "the",
        "is",
        "are",
        "was",
        "were",
        "be",
        "been",
        "being",
        "have",
        "has",
        "had",
        "do",
        "does",
        "did",
        "will",
        "would",
        "could",
        "should",
        "may",
        "might",
        "shall",
        "can",
        "need",
        "dare",
        "ought",
        "used",
        "to",
        "of",
        "in",
        "for",
        "on",
        "with",
        "at",
        "by",
        "from",
        "as",
        "into",
        "through",
        "during",
        "before",
        "after",
        "above",
        "below",
        "up",
        "down",
        "out",
        "off",
        "over",
        "under",
        "again",
        "further",
        "then",
        "once",
        "i",
        "me",
        "my",
        "we",
        "our",
        "you",
        "your",
        "it",
        "its",
        "this",
        "that",
        "these",
        "those",
        "and",
        "but",
        "or",
        "nor",
        "so",
        "yet",
        "both",
        "either",
        "not",
        "no",
        "what",
        "how",
        "when",
        "where",
        "who",
        "which",
        "please",
        "help",
        "let",
        "just",
        "get",
        "want",
        "make",
        "like",
        "know",
        "think",
        "look",
        "go",
        "see",
        "come",
        "take",
        "use",
        "find",
        "tell",
        "ask",
        "work",
        "seem",
        "feel",
        "try",
        "leave",
        "call",
        "keep",
        "here",
        "there",
    }
)


def extract_keywords(prompt: str) -> str:
    """
    Extract search keywords from user prompt.

    Lowercases, removes punctuation, filters stop words, returns top 6 terms
    joined by spaces.
    """
    cleaned = re.sub(r"[^\w\s]", " ", prompt.lower())
    words = cleaned.split()
    filtered = [w for w in words if w and w not in STOP_WORDS]
    return " ".join(filtered[:6])


def count_user_messages(transcript_path: str) -> int:
    """
    Count user messages already in the transcript.

    Read transcript_path, parse each JSON line, count where message.role == 'user'.
    Return 0 on any error (treat as first message if we can't read transcript).
    """
    path = Path(transcript_path)
    count = 0
    with contextlib.suppress(OSError):
        lines = path.read_text(encoding="utf-8").splitlines()
        for line in lines:
            stripped = line.strip()
            if stripped:
                parsed: dict | None = None
                with contextlib.suppress(json.JSONDecodeError):
                    parsed = cast("dict | None", json.loads(stripped))
                if parsed is not None:
                    msg = parsed.get("message", {})
                    if msg.get("role") == "user":
                        count += 1
    return count


def search_memory(query: str) -> list[dict]:
    """Search Basic Memory for notes matching the query."""
    result = subprocess.run(  # noqa: S603
        [  # noqa: S607
            "mise",
            "exec",
            "--",
            "basic-memory",
            "tool",
            "search-notes",
            "--query",
            query,
            "--page-size",
            "5",
        ],
        capture_output=True,
        text=True,
        check=False,
        timeout=2,
    )
    if result.returncode != 0 or not result.stdout.strip():
        return []
    parsed: list[dict] | None = None
    with contextlib.suppress(json.JSONDecodeError):
        parsed = cast("list[dict] | None", json.loads(result.stdout))
    if parsed is None:
        return []
    if isinstance(parsed, list):
        return parsed
    return []


def format_results(results: list[dict]) -> str:
    """
    Format search results as a context block for injection.

    Returns empty string if results is empty.
    Format:
      Relevant Basic Memory notes:
      - <title> (<permalink>)
      - ...
    """
    if not results:
        return ""
    lines = ["Relevant Basic Memory notes:"]
    for item in results:
        title = item.get("title", "")
        permalink = item.get("permalink", "")
        if title and permalink:
            lines.append(f"- {title} ({permalink})")
        elif title:
            lines.append(f"- {title}")
    if len(lines) == 1:
        return ""
    return "\n".join(lines)


def main() -> None:
    """Inject relevant Basic Memory context for the first prompt of a session."""
    ctx = create_context()
    try:
        if not isinstance(ctx, UserPromptSubmitContext):
            ctx.output.exit_success()  # ty: ignore[unresolved-attribute]
            return

        if count_user_messages(ctx.transcript_path) >= 1:
            ctx.output.exit_success()
            return

        keywords = extract_keywords(ctx.prompt)
        if not keywords:
            ctx.output.exit_success()
            return

        results = search_memory(keywords)
        context_text = format_results(results)

        if context_text:
            ctx.output.add_context(context_text)
        else:
            ctx.output.exit_success()

    except (
        OSError,
        ValueError,
        KeyError,
        RuntimeError,
        AttributeError,
        subprocess.TimeoutExpired,
    ) as e:
        LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
        with LOG_FILE.open("a") as f:
            f.write(f"[prompt_context error] {e}\n")
        ctx.output.exit_success()  # ty: ignore[unresolved-attribute]


if __name__ == "__main__":
    main()
