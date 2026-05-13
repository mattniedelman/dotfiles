#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.claude/hooks
"""
PostToolUse hook: Track Ralph autonomous loop progress.

Monitors ralph-* subagent calls during /ralph execution:
- Persists state to .ralph/state.json after each task
- Tracks circuit breaker counters
- Writes progress log for external monitoring
- Injects status summary back to agent
"""
# /// script
# requires-python = ">=3.11"
# dependencies = ["cchooks>=0.1.0"]
# ///

from __future__ import annotations

import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

from cchooks import create_context
from cchooks import PostToolUseContext

RALPH_DIR = ".ralph"
STATE_FILE = "state.json"
PROGRESS_LOG = "logs/progress.log"
CB_FILE = "circuit-breaker.json"
CB_NO_PROGRESS_THRESHOLD = 3
CB_SAME_TASK_THRESHOLD = 3
CB_MAX_ITERATIONS = 20


def get_git_head(workspace: Path) -> str:
    """Return current HEAD SHA, or empty string if not a git repo."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=workspace,
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return ""
    if result.returncode != 0:
        return ""
    return result.stdout.strip()


def get_workspace(ctx: PostToolUseContext) -> Path | None:
    """Get workspace path from context."""
    raw = ctx._input_data  # noqa: SLF001
    cwd = raw.get("cwd")
    if cwd:
        return Path(cwd)
    return None


def extract_files_changed(ctx: PostToolUseContext) -> list[str]:
    """Extract files changed from subagent output."""
    raw = ctx._input_data  # noqa: SLF001
    file_changes = raw.get("file_changes", [])
    return [fc.get("path", "") for fc in file_changes if fc.get("path")]


def extract_from_output(output: str, pattern: str) -> str:
    """Extract value from structured output."""
    match = re.search(pattern, output, re.MULTILINE)
    return match.group(1).strip() if match else ""


def parse_subagent_output(ctx: PostToolUseContext) -> dict:
    """Parse structured output from ralph subagents."""
    # Claude Code: Agent tool response is in tool_response
    response = ctx.tool_response
    content = response.get("content", "")
    if isinstance(content, list):
        output = " ".join(
            block.get("text", "") for block in content
            if isinstance(block, dict) and block.get("type") == "text"
        )
    else:
        output = str(content)

    return {
        "task": extract_from_output(output, r"\*\*Task:\*\*\s*(.+)"),
        "verdict": "PASS" if "PASS" in output else "FAIL" if "FAIL" in output else "unknown",
        "files_changed": [],  # Not available in Claude Code Agent PostToolUse
    }


def load_json(path: Path, default: dict) -> dict:
    """Load JSON file or return default."""
    if path.exists():
        return json.loads(path.read_text())
    return default.copy()


def save_json(path: Path, data: dict) -> None:
    """Save dict to JSON file, creating parent dirs."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2))


def append_log(path: Path, message: str) -> None:
    """Append timestamped message to log file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now(timezone.utc).strftime("%H:%M:%S")
    with path.open("a") as f:
        f.write(f"[{timestamp}] {message}\n")


def update_circuit_breaker(
    cb_path: Path, current_task: str, current_head: str, iteration: int
) -> dict:
    """Update circuit breaker state using git HEAD as progress signal."""
    cb = load_json(cb_path, {
        "no_progress_count": 0,
        "same_task_count": 0,
        "last_task": "",
        "last_head": "",
        "tripped": False,
        "trip_reason": None,
    })

    prior_head = cb.get("last_head", "")
    head_advanced = bool(current_head) and bool(prior_head) and current_head != prior_head
    no_git_signal = not current_head

    if head_advanced:
        cb["no_progress_count"] = 0
    elif no_git_signal:
        cb["no_progress_count"] = cb.get("no_progress_count", 0)
    else:
        cb["no_progress_count"] = cb.get("no_progress_count", 0) + 1
    cb["last_head"] = current_head or prior_head

    if current_task and current_task == cb.get("last_task", ""):
        cb["same_task_count"] = cb.get("same_task_count", 0) + 1
    else:
        cb["same_task_count"] = 0
        cb["last_task"] = current_task

    if cb["no_progress_count"] >= CB_NO_PROGRESS_THRESHOLD:
        cb["tripped"] = True
        cb["trip_reason"] = (
            f"No new commits for {cb['no_progress_count']} iterations"
        )
    elif cb["same_task_count"] >= CB_SAME_TASK_THRESHOLD:
        cb["tripped"] = True
        cb["trip_reason"] = f"Stuck on same task for {cb['same_task_count']} iterations"
    elif iteration >= CB_MAX_ITERATIONS:
        cb["tripped"] = True
        cb["trip_reason"] = f"Hit max iterations safety net ({CB_MAX_ITERATIONS})"

    save_json(cb_path, cb)
    return cb


def update_state(state_path: Path, parsed: dict, tool_name: str) -> dict:
    """Update Ralph state, return current state."""
    state = load_json(state_path, {
        "loop_count": 0,
        "started_at": datetime.now(timezone.utc).isoformat(),
        "phase": "setup",
        "tasks_complete": 0,
        "last_subagent": None,
    })

    state["loop_count"] = state.get("loop_count", 0) + 1
    state["last_updated"] = datetime.now(timezone.utc).isoformat()
    state["last_subagent"] = tool_name
    state["last_task"] = parsed.get("task", "")
    state["last_verdict"] = parsed.get("verdict", "")

    if tool_name == "ralph-quality-review" and parsed.get("verdict") == "PASS":
        state["tasks_complete"] = state.get("tasks_complete", 0) + 1

    save_json(state_path, state)
    return state


def main() -> None:
    """Monitor Ralph loop progress after subagent calls."""
    ctx = create_context()

    if not isinstance(ctx, PostToolUseContext):
        ctx.output.exit_success()
        return

    tool_name = ctx.tool_name
    if tool_name != "Agent":
        ctx.output.exit_success()
        return

    subagent_type = ctx.tool_input.get("subagent_type", "")
    if not subagent_type.startswith("ralph-"):
        ctx.output.exit_success()
        return

    tool_name = subagent_type  # use subagent_type as identifier going forward

    workspace = get_workspace(ctx)
    if not workspace:
        ctx.output.exit_success()
        return

    # Initialize .ralph dir if this is first ralph subagent call
    ralph_dir = workspace / RALPH_DIR
    if not ralph_dir.exists():
        ralph_dir.mkdir(parents=True)
        save_json(ralph_dir / STATE_FILE, {
            "started_at": datetime.now(timezone.utc).isoformat(),
            "loop_count": 0,
            "phase": "building",
        })

    parsed = parse_subagent_output(ctx)
    state = update_state(ralph_dir / STATE_FILE, parsed, tool_name)
    cb = update_circuit_breaker(
        ralph_dir / CB_FILE,
        parsed.get("task", ""),
        get_git_head(workspace),
        state.get("loop_count", 0),
    )

    # Log for external monitoring
    agent_short = tool_name.replace("ralph-", "")
    log_msg = (
        f"{agent_short} | "
        f"Task: {parsed.get('task', 'unknown')[:40]} | "
        f"Verdict: {parsed.get('verdict', '-')} | "
        f"CB: {cb['no_progress_count']}/{CB_NO_PROGRESS_THRESHOLD}"
    )
    append_log(ralph_dir / PROGRESS_LOG, log_msg)

    # Build status for agent
    status = f"📊 Ralph #{state['loop_count']} | {agent_short} | {parsed.get('verdict', '-')}"

    if cb.get("tripped"):
        status += f" | 🔴 CIRCUIT BREAKER: {cb['trip_reason']} - STOP and ask user"

    ctx.output.add_context(status)


if __name__ == "__main__":
    main()
