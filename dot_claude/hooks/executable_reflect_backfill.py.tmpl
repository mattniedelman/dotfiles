#!/usr/bin/env -S uv run --quiet --script
# /// script
# dependencies = []
# ///
"""
Retroactively run session_reflect over historical transcripts.

Mirrors the logic in session_reflect.py but enumerates transcripts from
~/.claude/projects/*/*.jsonl, skips those with an existing marker, and caps
concurrent child `claude -p` processes.
"""

from __future__ import annotations

import argparse
import contextlib
import datetime
import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import IO

MAX_MESSAGES = 60
MAX_TEXT_LENGTH = 400
MIN_HUMAN_TURNS = 8
CHILD_MODEL = "haiku"
CHILD_TOOLS = "mcp__basic-memory__write_note,mcp__basic-memory__search_notes"
CLAUDE_BIN = "/home/mattniedelman/.local/bin/claude"
REFLECTED_DIR = Path.home() / ".claude" / "hooks" / "logs" / "reflected"
LOG_FILE = Path.home() / ".claude" / "hooks" / "logs" / "reflect_backfill.log"
PROJECTS_DIR = Path.home() / ".claude" / "projects"
UTC = datetime.timezone.utc
POLL_INTERVAL_SECONDS = 0.5
DRY_RUN_PREVIEW = 20


def emit(line: str) -> None:
    """Write a line to stdout and flush."""
    sys.stdout.write(line + "\n")
    sys.stdout.flush()


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


def extract_messages(transcript_path: Path) -> list[dict[str, str]]:
    """Return truncated user/assistant messages from a transcript JSONL file."""
    messages: list[dict[str, str]] = []
    for raw in transcript_path.read_text(
        encoding="utf-8", errors="ignore"
    ).splitlines():
        stripped = raw.strip()
        if not stripped:
            continue
        parsed: dict | None = None
        with contextlib.suppress(json.JSONDecodeError):
            parsed = json.loads(stripped)
        if parsed is None:
            continue
        msg = parsed.get("message", {})
        role = msg.get("role")
        if role in ("user", "assistant"):
            text = extract_text(msg.get("content", ""))
            if len(text) > MAX_TEXT_LENGTH:
                text = text[:MAX_TEXT_LENGTH] + "..."
            messages.append({"role": role, "text": text})
    return messages[-MAX_MESSAGES:]


def count_human_messages(messages: list[dict[str, str]]) -> int:
    """Return number of user-role messages."""
    return sum(1 for m in messages if m["role"] == "user")


def _decode_project_dir(encoded: str) -> str:
    """Approximately decode the encoded project directory name."""
    if encoded.startswith("-"):
        return "/" + encoded[1:].replace("--", "\x00").replace("-", "/").replace(
            "\x00", "-"
        )
    return encoded


def derive_project_name(transcript_path: Path) -> str:
    """Derive a human-readable project name from the transcript path."""
    encoded = transcript_path.parent.name
    decoded = _decode_project_dir(encoded)
    return Path(decoded).name if decoded.startswith("/") else encoded


def derive_workspace(transcript_path: Path) -> str:
    """Return an existing workspace path for the child cwd, or HOME as fallback."""
    encoded = transcript_path.parent.name
    decoded = _decode_project_dir(encoded)
    candidate = Path(decoded) if decoded.startswith("/") else None
    if candidate is not None and candidate.exists():
        return str(candidate)
    return str(Path.home())


def session_id_from_path(transcript_path: Path) -> str:
    """Return session id (filename stem) for a transcript."""
    return transcript_path.stem


def transcript_mtime(transcript_path: Path) -> float:
    """Return the transcript file's modification time."""
    return transcript_path.stat().st_mtime


def build_reflect_prompt(
    messages: list[dict[str, str]], project_name: str, today: str
) -> str:
    """Build the reflection prompt for the child claude session."""
    transcript_lines: list[str] = []
    for m in messages:
        label = "HUMAN" if m["role"] == "user" else "ASSISTANT"
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


def enumerate_candidates() -> list[tuple[Path, str, int, float, list[dict[str, str]]]]:
    """Collect qualifying, not-yet-reflected transcripts."""
    REFLECTED_DIR.mkdir(parents=True, exist_ok=True)
    out: list[tuple[Path, str, int, float, list[dict[str, str]]]] = []
    for jsonl in PROJECTS_DIR.glob("*/*.jsonl"):
        sid = session_id_from_path(jsonl)
        if (REFLECTED_DIR / sid).exists():
            continue
        try:
            messages = extract_messages(jsonl)
        except (OSError, ValueError):
            continue
        human = count_human_messages(messages)
        if human < MIN_HUMAN_TURNS:
            continue
        out.append((jsonl, sid, human, transcript_mtime(jsonl), messages))
    return out


def run_child(
    transcript_path: Path,
    session_id: str,
    messages: list[dict[str, str]],
    log_handle: IO[str],
) -> subprocess.Popen:
    """Spawn a child claude -p reflection process for one session."""
    project_name = derive_project_name(transcript_path)
    today = datetime.datetime.now(UTC).date().isoformat()
    prompt = build_reflect_prompt(messages, project_name, today)
    workspace = derive_workspace(transcript_path)
    env = {**os.environ, "CLAUDE_SESSION_REFLECT": "1"}
    (REFLECTED_DIR / session_id).touch()
    log_handle.write(f"\n=== {session_id} :: {project_name} ===\n")
    log_handle.flush()
    return subprocess.Popen(  # noqa: S603
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
        cwd=workspace,
        start_new_session=True,
    )


def parse_args() -> argparse.Namespace:
    """Parse CLI args."""
    p = argparse.ArgumentParser()
    p.add_argument("--concurrency", type=int, default=3)
    p.add_argument(
        "--limit", type=int, default=0, help="max sessions to process (0=all)"
    )
    p.add_argument(
        "--since", type=str, default="", help="YYYY-MM-DD lower bound on mtime"
    )
    p.add_argument(
        "--project", type=str, default="", help="substring filter on project dir name"
    )
    p.add_argument("--dry-run", action="store_true")
    p.add_argument(
        "--oldest-first",
        action="store_true",
        help="process oldest sessions first (default: newest first)",
    )
    return p.parse_args()


def collect_candidates(
    args: argparse.Namespace,
) -> list[tuple[Path, str, int, float, list[dict[str, str]]]]:
    """Filter and sort enumerated candidates per CLI args."""
    since_ts = 0.0
    if args.since:
        since_ts = (
            datetime.datetime.strptime(args.since, "%Y-%m-%d")
            .replace(tzinfo=UTC)
            .timestamp()
        )
    items = [
        (jsonl, sid, human, mtime, msgs)
        for (jsonl, sid, human, mtime, msgs) in enumerate_candidates()
        if mtime >= since_ts and (not args.project or args.project in jsonl.parent.name)
    ]
    items.sort(key=lambda t: t[3], reverse=not args.oldest_first)
    if args.limit > 0:
        items = items[: args.limit]
    return items


def run_pool(
    candidates: list[tuple[Path, str, int, float, list[dict[str, str]]]],
    concurrency: int,
) -> None:
    """Run reflection children with bounded concurrency."""
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    started = time.time()
    processed = 0
    total = len(candidates)
    with LOG_FILE.open("a") as log_handle:
        log_handle.write(
            f"\n### backfill start {datetime.datetime.now(UTC).isoformat()} "
            f"candidates={total} concurrency={concurrency}\n"
        )
        log_handle.flush()
        running: list[tuple[subprocess.Popen, str]] = []
        queue = list(candidates)
        while queue or running:
            while queue and len(running) < concurrency:
                jsonl, sid, _, _, messages = queue.pop(0)
                try:
                    proc = run_child(jsonl, sid, messages, log_handle)
                except (OSError, ValueError) as e:
                    emit(f"  failed to spawn {sid[:8]}: {e}")
                    continue
                running.append((proc, sid))
                processed += 1
                emit(f"[{processed}/{total}] spawned {sid[:8]} ({jsonl.parent.name})")
            time.sleep(POLL_INTERVAL_SECONDS)
            still: list[tuple[subprocess.Popen, str]] = []
            for proc, sid in running:
                if proc.poll() is None:
                    still.append((proc, sid))
                else:
                    log_handle.write(f"=== {sid} exited rc={proc.returncode} ===\n")
                    log_handle.flush()
            running = still
        elapsed = time.time() - started
        log_handle.write(
            f"### backfill done elapsed={elapsed:.1f}s processed={processed}\n"
        )
    emit(f"done. processed={processed} elapsed={elapsed:.1f}s")


def main() -> None:
    """Entry point."""
    args = parse_args()
    candidates = collect_candidates(args)
    emit(f"candidates: {len(candidates)}")
    if args.dry_run:
        for jsonl, sid, human, mtime, _ in candidates[:DRY_RUN_PREVIEW]:
            stamp = datetime.datetime.fromtimestamp(mtime, UTC).strftime("%Y-%m-%d")
            emit(f"  {stamp}  {sid[:8]}  human={human:3d}  {jsonl.parent.name}")
        if len(candidates) > DRY_RUN_PREVIEW:
            emit(f"  ... and {len(candidates) - DRY_RUN_PREVIEW} more")
        return
    run_pool(candidates, args.concurrency)


if __name__ == "__main__":
    main()
