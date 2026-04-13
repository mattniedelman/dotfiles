#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.claude/hooks
# /// script
# dependencies = ["pyyaml", "cchooks"]
# ///
"""
SessionStart hook: Inject project context and remind to check basic-memory.

Works with both Augment CLI and Claude Code via the unified adapter.
"""

from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

import yaml
from cchooks import SessionStartContext, create_context

AGENTS_DIRS = [
    Path.home() / ".claude" / "agents",
    Path.home() / ".augment" / "agents",
]
MAX_DESC_LENGTH = 120
TRUNCATED_DESC_LENGTH = 117

PACKAGE_MANAGERS = [
    ("poetry.lock", "poetry run pytest"),
    ("uv.lock", "uv run pytest"),
    ("package.json", "npm test"),
    ("Cargo.toml", "cargo test"),
    ("go.mod", "go test ./..."),
]


def get_recent_memory() -> str:
    """Return formatted recent Basic Memory activity, or empty string on failure."""
    try:
        result = subprocess.run(
            [  # noqa: S607
                "mise", "exec", "--", "basic-memory", "tool",
                "recent-activity", "--timeframe", "7d", "--page-size", "5",
            ],
            capture_output=True,
            text=True,
            check=False,
            timeout=10,
        )
        if result.returncode != 0:
            return ""
        items = json.loads(result.stdout)
        if not items:
            return ""
        lines = [f"- {item['title']}" for item in items if item.get("title")]
        if not lines:
            return ""
        return "\n".join(lines)
    except (OSError, ValueError, KeyError, TypeError, subprocess.TimeoutExpired):
        return ""


def discover_agents() -> list[dict[str, str]]:
    """Scan agents directories and extract name/description from frontmatter."""
    agents: dict[str, dict[str, str]] = {}
    for agents_dir in AGENTS_DIRS:
        if not agents_dir.exists():
            continue
        for agent_file in sorted(agents_dir.glob("*.md")):
            content = agent_file.read_text()
            match = re.match(r"^---\s*\n(.+?)\n---", content, re.DOTALL)
            if not match:
                continue
            try:
                frontmatter = yaml.safe_load(match.group(1))
                if frontmatter and "name" in frontmatter:
                    name = frontmatter["name"]
                    if name not in agents:
                        agents[name] = {
                            "name": name,
                            "description": frontmatter.get("description", "").strip(),
                        }
            except yaml.YAMLError:
                continue
    return list(agents.values())


def format_agents_section(agents: list[dict[str, str]]) -> str:
    """Format agents list for context injection."""
    if not agents:
        return ""

    lines = ["\n**Available Subagents** - delegate to these for focused work:"]
    for agent in agents:
        desc = agent["description"]
        if len(desc) > MAX_DESC_LENGTH:
            desc = desc[:TRUNCATED_DESC_LENGTH] + "..."
        lines.append(f"- `{agent['name']}`: {desc}")
    lines.append(
        "\nSubagents run in parallel with independent context. Use proactively."
    )
    return "\n".join(lines)


def get_git_context(workspace: str) -> str:
    """Get current branch and last commit message."""
    project_path = Path(workspace)
    if not (project_path / ".git").exists():
        return ""

    try:
        branch = subprocess.run(
            ["git", "branch", "--show-current"],  # noqa: S607
            capture_output=True, text=True, check=False, cwd=workspace,
        ).stdout.strip()

        last_commit = subprocess.run(
            ["git", "log", "-1", "--pretty=%s"],  # noqa: S607
            capture_output=True, text=True, check=False, cwd=workspace,
        ).stdout.strip()
    except OSError:
        return ""

    if not branch or branch in {"main", "master"}:
        if last_commit:
            return f"Last commit: {last_commit}"
        return ""

    if last_commit:
        return f"Branch: {branch} | Last commit: {last_commit}"
    return f"Branch: {branch}"


def get_test_command(project_path: Path) -> str | None:
    """Detect the appropriate test command for the project."""
    for lock_file, command in PACKAGE_MANAGERS:
        if (project_path / lock_file).exists():
            return command

    if (project_path / "tests").is_dir() or (project_path / "test").is_dir():
        return "pytest"

    return None


def main() -> None:
    """Inject project context at session start."""
    ctx = create_context()

    if not isinstance(ctx, SessionStartContext):
        ctx.output.exit_success()
        return

    workspace = (
        ctx.claude_project_dir
        or ctx._input_data.get("claude_project_dir", "")  # noqa: SLF001
        or next(iter(ctx._input_data.get("workspace_roots", [])), "")  # noqa: SLF001
    )

    if not workspace:
        ctx.output.exit_success()
        return

    project = Path(workspace).name
    agents = discover_agents()
    agents_section = format_agents_section(agents)
    git_context = get_git_context(workspace)
    test_command = get_test_command(Path(workspace))

    test_tip = ""
    if test_command:
        test_tip = (
            f"\n\nNOTE: Run `{test_command}` first to orient yourself to the codebase."
        )

    git_line = f"\n{git_context}" if git_context else ""

    recent_memory = get_recent_memory()
    if recent_memory:
        memory_section = (
            f"\nRecent Basic Memory activity (last 7 days):\n{recent_memory}"
        )
    else:
        memory_section = (
            "\nCheck basic-memory for prior context on this project:"
            "\n- Use build_context or recent_activity to see what's been worked on"
            "\n- Search for related notes before starting new work"
            "\n- Continue from previous decisions and learnings"
        )

    context_message = f"""Project: {project}{git_line}
{agents_section}{memory_section}{test_tip}"""

    ctx.output.add_context(context_message)


if __name__ == "__main__":
    main()
