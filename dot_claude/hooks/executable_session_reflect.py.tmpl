#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.claude/hooks
# /// script
# dependencies = ["cchooks"]
# ///
"""
Stop hook: Fire-and-forget session reflection into Basic Memory.

Spawns a child `claude -p` session that extracts decisions and learnings
from the completed session transcript and writes them to Basic Memory.
Works with AWS Bedrock (inherits settings.json config).
"""

from __future__ import annotations

import contextlib
import datetime
import json
import os
import subprocess
from pathlib import Path

from cchooks import StopContext, create_context

MAX_MESSAGES = 60
MAX_TEXT_LENGTH = 400
MIN_HUMAN_TURNS = 8
CHILD_MODEL = "haiku"
CHILD_TOOLS = "mcp__basic-memory__write_note,mcp__basic-memory__search_notes"
CLAUDE_BIN = "/home/mattniedelman/.local/bin/claude"
REFLECTED_DIR = Path.home() / ".claude" / "hooks" / "logs" / "reflected"
LOG_FILE = Path.home() / ".claude" / "hooks" / "logs" / "session_reflect.log"


def extract_text(content: str | list[dict]) -> str:
    """Extract plain text from a message content field (string or block list)."""
    if isinstance(content, str):
        return content
    parts: list[str] = []
    for block in content:
        if isinstance(block, dict) and block.get("type") == "text":
            text = block.get("text", "")
            if isinstance(text, str):
                parts.append(text)
    return "\n".join(parts)


def extract_messages(transcript_path: str) -> list[dict[str, str]]:
    """
    Extract human and assistant messages from session JSONL transcript.

    Returns list of dicts with 'role' and 'text' keys.
    Takes last 60 messages max, truncates each to 400 chars.
    """
    path = Path(transcript_path)
    raw_lines = path.read_text(encoding="utf-8").splitlines()
    messages: list[dict[str, str]] = []
    for line in raw_lines:
        stripped = line.strip()
        if stripped:
            parsed: dict | None = None
            with contextlib.suppress(json.JSONDecodeError):
                parsed = json.loads(stripped)
            if parsed is not None:
                msg = parsed.get("message", {})
                role = msg.get("role")
                if role in ("user", "assistant"):
                    text = extract_text(msg.get("content", ""))
                    if len(text) > MAX_TEXT_LENGTH:
                        text = text[:MAX_TEXT_LENGTH] + "..."
                    messages.append({"role": role, "text": text})
    return messages[-MAX_MESSAGES:]


def count_human_messages(messages: list[dict[str, str]]) -> int:
    """Count messages with role 'user'."""
    return sum(1 for m in messages if m["role"] == "user")


def derive_project_name(transcript_path: str) -> str:
    """
    Derive human-readable project name from transcript path.

    Path format: ~/.claude/projects/-home-mattniedelman-git-myrepo/session.jsonl
    The encoded dir replaces '/' and '.' with '-'. Decode is approximate:
    '--' is treated as a literal dash in the original path. Paths with dots
    (e.g. '.claude') produce an approximate name; used for display only.
    E.g. -home-mattniedelman-git-myrepo -> /home/mattniedelman/git/myrepo -> myrepo
    """
    encoded = Path(transcript_path).parent.name
    if encoded.startswith("-"):
        decoded = (
            encoded[1:].replace("--", "\x00").replace("-", "/").replace("\x00", "-")
        )
        decoded = "/" + decoded
        return Path(decoded).name
    return encoded


def build_reflect_prompt(
    messages: list[dict[str, str]], project_name: str, today: str
) -> str:
    """Build the reflection prompt for the child claude session."""
    transcript_lines: list[str] = []
    for m in messages:
        if m["role"] == "user":
            label = "HUMAN"
        else:
            label = "ASSISTANT"
        transcript_lines.append(f"{label}: {m['text']}")
    transcript_text = "\n".join(transcript_lines)
    pref_example = '"don\'t do X", "use Y not Z", "I want it to always..."'
    skip_line = '1. If nothing meets the bar above: output "SKIP" and stop'
    search_line = (
        "2. If worth capturing: use search_notes first to check for existing notes"
    )
    return (
        f"You are doing a post-session memory extraction for project: {project_name}\n"
        f"Date: {today}\n"
        "\n"
        "Review the transcript below. Write to Basic Memory ONLY if you find:\n"
        f"- Explicit user corrections or stated preferences (e.g. {pref_example})\n"
        "- Architectural or design decisions with stated rationale\n"
        "- Non-obvious debugging root causes discovered during the session\n"
        "- Patterns explicitly established for this codebase\n"
        "\n"
        "Do NOT capture:\n"
        "- Routine code written or tasks completed\n"
        "- Information already obvious from the code itself\n"
        "- General programming concepts\n"
        "\n"
        "Process:\n"
        f"{skip_line} immediately without calling any tools\n"
        f"{search_line}\n"
        "3. Write 1-3 concise notes max. Folder: journal/sessions/auto/\n"
        "\n"
        "<transcript>\n"
        f"{transcript_text}\n"
        "</transcript>"
    )


def write_marker(session_id: str) -> None:
    """Write session reflection marker file to prevent double-reflection."""
    REFLECTED_DIR.mkdir(parents=True, exist_ok=True)
    (REFLECTED_DIR / session_id).touch()


def derive_workspace(transcript_path: str) -> str:
    """
    Derive workspace path from transcript path for child session cwd.

    Decode is approximate: paths with dots (e.g. '.claude') will not resolve
    and fall back to Path.home(). Paths without dots decode correctly.
    If derived path does not exist, fall back to Path.home().
    """
    encoded = Path(transcript_path).parent.name
    if encoded.startswith("-"):
        decoded = (
            encoded[1:].replace("--", "\x00").replace("-", "/").replace("\x00", "-")
        )
        candidate = Path("/" + decoded)
        if candidate.exists():
            return str(candidate)
    return str(Path.home())


def spawn_reflection(prompt: str, log_file: Path, transcript_path: str) -> None:
    """Spawn fire-and-forget child claude session for reflection."""
    env = {**os.environ, "CLAUDE_SESSION_REFLECT": "1"}
    log_file.parent.mkdir(parents=True, exist_ok=True)
    workspace = derive_workspace(transcript_path)
    with log_file.open("a") as log_handle:
        subprocess.Popen(  # noqa: S603
            [
                CLAUDE_BIN,
                "-p",
                prompt,
                "--model",
                CHILD_MODEL,
                "--allowedTools",
                CHILD_TOOLS,
            ],
            env=env,
            stdout=log_handle,
            stderr=subprocess.STDOUT,
            start_new_session=True,
            cwd=workspace,
        )


def main() -> None:
    """Fire-and-forget session reflection at Stop hook."""
    ctx = create_context()
    try:
        # Guard 1: we are the child reflection session -- skip
        if os.environ.get("CLAUDE_SESSION_REFLECT") == "1":
            ctx.output.exit_success()  # ty: ignore[unresolved-attribute]
            return

        # Guard 2: not a Stop hook -- skip
        if not isinstance(ctx, StopContext):
            ctx.output.exit_success()  # ty: ignore[unresolved-attribute]
            return

        # Guard 3 (per spec): stop hook continuation -- skip
        if ctx.stop_hook_active:
            ctx.output.exit_success()
            return

        messages = extract_messages(ctx.transcript_path)
        human_message_count = count_human_messages(messages)
        if human_message_count < MIN_HUMAN_TURNS:
            ctx.output.exit_success()
            return

        marker = REFLECTED_DIR / ctx.session_id
        if marker.exists():
            ctx.output.exit_success()
            return

        project_name = derive_project_name(ctx.transcript_path)
        today = datetime.datetime.now(datetime.timezone.utc).date().isoformat()
        prompt = build_reflect_prompt(messages, project_name, today)
        write_marker(ctx.session_id)
        spawn_reflection(prompt, LOG_FILE, ctx.transcript_path)

        ctx.output.exit_success()

    except (OSError, ValueError, KeyError, RuntimeError, AttributeError) as e:
        LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
        with LOG_FILE.open("a") as f:
            f.write(f"[session_reflect error] {e}\n")
        ctx.output.exit_success()  # ty: ignore[unresolved-attribute]


if __name__ == "__main__":
    main()
