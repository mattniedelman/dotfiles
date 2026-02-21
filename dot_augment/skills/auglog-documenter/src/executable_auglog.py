#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "pydantic>=2.0",
#     "pydantic-settings>=2.0",
# ]
# ///
"""
Auglog - Session loading and formatting for Augment CLI sessions.

This script uses PEP 723 inline dependencies for portability.

CLI usage:
    uv run auglog.py list              # List recent sessions
    uv run auglog.py list --json       # Output as JSON
    uv run auglog.py show <session_id> # Show formatted session

Python import:
    from auglog import Session, load, load_all, list_all
"""

from __future__ import annotations

import json
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, cast

from pydantic import BaseModel, ConfigDict, Field, field_validator
from pydantic_settings import CliApp, CliSubCommand

# =============================================================================
# Pydantic Models (Session Data)
# =============================================================================


class ToolUse(BaseModel):
    """A tool invocation by the agent."""

    tool_use_id: str
    tool_name: str
    input_json: str
    is_partial: bool = False


class ToolResult(BaseModel):
    """Result from a tool invocation."""

    tool_use_id: str
    content: str
    is_error: bool = False


class RequestNode(BaseModel):
    """A node in the request (user message, IDE state, or tool result)."""

    id: int
    type: int
    text_node: dict[str, Any] | None = None
    ide_state_node: dict[str, Any] | None = None
    tool_result_node: ToolResult | None = None


class ThinkingContent(BaseModel):
    """Extended thinking content with summary and optional encrypted content."""

    summary: str = ""
    content: str | None = None
    encrypted_content: str | None = None
    openai_responses_api_item_id: str | None = None


class ResponseNode(BaseModel):
    """A node in the response (text content or tool use)."""

    id: int
    type: int
    content: str = ""
    tool_use: ToolUse | None = None
    thinking: str | ThinkingContent | None = None


class ExchangeData(BaseModel):
    """The inner exchange data with request/response details."""

    request_message: str
    response_text: str
    request_id: str
    request_nodes: list[RequestNode] = Field(default_factory=list)
    response_nodes: list[ResponseNode] = Field(default_factory=list)


class Exchange(BaseModel):
    """A single exchange (turn) in the conversation."""

    model_config = ConfigDict(populate_by_name=True)

    exchange: ExchangeData
    completed: bool = True
    sequence_id: float = Field(alias="sequenceId")
    finished_at: datetime | None = Field(default=None, alias="finishedAt")
    changed_files: list[str] = Field(default_factory=list, alias="changedFiles")

    @field_validator("changed_files", mode="before")
    @classmethod
    def normalize_changed_files(cls, v: Any) -> list[str]:
        """Handle both string lists and object lists for changedFiles."""
        if not v:
            return []
        result: list[str] = []
        for item in v:
            if isinstance(item, str):
                result.append(item)
            elif isinstance(item, dict):
                item_dict = cast("dict[str, Any]", item)
                raw_path = (
                    item_dict.get("old_path")
                    or item_dict.get("path")
                    or item_dict.get("new_path")
                )
                if isinstance(raw_path, str):
                    result.append(raw_path)
        return result

    def format(self, index: int, *, max_response_length: int = 2000) -> str:
        """
        Format this exchange as markdown.

        Args:
            index: Exchange number (1-based)
            max_response_length: Truncate responses longer than this

        Returns:
            Markdown formatted exchange

        """
        lines: list[str] = []
        lines.append(f"### Exchange {index}")
        lines.append("")

        # User message
        user_msg = self.exchange.request_message.strip()
        if user_msg:
            lines.append(f"**Me:** {user_msg}")
        else:
            lines.append("**Me:** *(no message)*")
        lines.append("")

        # Agent response (truncate very long responses)
        response = self.exchange.response_text.strip()
        if len(response) > max_response_length:
            response = response[:max_response_length] + "\n\n*[response truncated]*"
        lines.append(f"**Agent:** {response}")
        lines.append("")

        # Tools used
        tools = [
            node.tool_use.tool_name
            for node in self.exchange.response_nodes
            if node.tool_use
        ]
        if tools:
            lines.append(f"*Tools used: {', '.join(tools)}*")
            lines.append("")

        # Files changed
        if self.changed_files:
            lines.append(f"*Files changed: {', '.join(self.changed_files)}*")
            lines.append("")

        return "\n".join(lines)


class AgentState(BaseModel):
    """Agent state stored in the session."""

    model_config = ConfigDict(populate_by_name=True)

    user_guidelines: str = Field(default="", alias="userGuidelines")
    workspace_guidelines: str = Field(default="", alias="workspaceGuidelines")
    agent_memories: str = Field(default="", alias="agentMemories")
    model_id: str = Field(default="", alias="modelId")


class Session(BaseModel):
    """A complete Augment CLI session."""

    model_config = ConfigDict(populate_by_name=True)

    session_id: str = Field(alias="sessionId")
    created: datetime
    modified: datetime
    chat_history: list[Exchange] = Field(default_factory=list, alias="chatHistory")
    agent_state: AgentState | None = Field(default=None, alias="agentState")
    root_task_uuid: str | None = Field(default=None, alias="rootTaskUuid")

    @property
    def title(self) -> str:
        """Get first user message as title (truncated to 100 chars)."""
        for ex in self.chat_history:
            msg = ex.exchange.request_message.strip()
            # Skip empty or trivially short messages
            if msg:
                first_line = msg.split("\n")[0].strip()
                if first_line:
                    return first_line[:100]
        return "(no title)"

    @property
    def exchange_count(self) -> int:
        """Number of exchanges in this session."""
        return len(self.chat_history)

    @property
    def duration_minutes(self) -> float | None:
        """Duration of session in minutes, if determinable."""
        if not self.chat_history:
            return None
        first_finished = self.chat_history[0].finished_at
        last_finished = self.chat_history[-1].finished_at
        if first_finished and last_finished:
            delta = last_finished - first_finished
            return delta.total_seconds() / 60
        return None

    @property
    def repos(self) -> set[str]:
        """Extract unique repository paths from workspace folders."""
        repos: set[str] = set()
        for ex in self.chat_history:
            for node in ex.exchange.request_nodes:
                if node.ide_state_node:
                    folders = node.ide_state_node.get("workspace_folders", [])
                    for folder in folders:
                        if repo := folder.get("repository_root"):
                            repos.add(repo)
        return repos

    @property
    def tools_used(self) -> set[str]:
        """Extract unique tool names used in this session."""
        tools: set[str] = set()
        for ex in self.chat_history:
            for node in ex.exchange.response_nodes:
                if node.tool_use:
                    tools.add(node.tool_use.tool_name)
        return tools

    @property
    def files_changed(self) -> set[str]:
        """
        Collect all files changed across all exchanges.

        Combines explicit changedFiles data with inference from file-modifying
        tool usage (save-file, str-replace-editor, etc.)
        """
        files: set[str] = set()
        file_modifying_tools = {
            "save-file",
            "str-replace-editor",
            "write_file_filesystem",
            "edit_file_filesystem",
            "remove-files",
        }

        for ex in self.chat_history:
            files.update(ex.changed_files)
            for node in ex.exchange.response_nodes:
                if node.tool_use and node.tool_use.tool_name in file_modifying_tools:
                    try:
                        input_data = json.loads(node.tool_use.input_json)
                        path = input_data.get("path")
                        if path:
                            files.add(path)
                        for fp in input_data.get("file_paths", []):
                            files.add(fp)
                    except (json.JSONDecodeError, TypeError):
                        pass  # Invalid JSON in tool input, skip file inference
        return files

    def format_log(self) -> str:
        """Format all exchanges as a markdown session log."""
        lines: list[str] = []
        lines.append("## Session Log")
        lines.append("")

        for i, exchange in enumerate(self.chat_history, 1):
            lines.append(exchange.format(i))

        return "\n".join(lines)


# =============================================================================
# Session Loading Functions
# =============================================================================


SESSIONS_DIR = Path.home() / ".augment" / "sessions"


def list_all(sessions_dir: Path | None = None) -> list[str]:
    """
    List all session IDs in the sessions directory.

    Args:
        sessions_dir: Path to sessions directory. Defaults to ~/.augment/sessions/

    Returns:
        List of session IDs (UUIDs without .json extension)

    """
    directory = sessions_dir if sessions_dir is not None else SESSIONS_DIR
    if not directory.exists():
        return []

    return sorted(path.stem for path in directory.glob("*.json"))


def load(session_id: str, sessions_dir: Path | None = None) -> Session:
    """
    Load a session by ID.

    Args:
        session_id: The session UUID
        sessions_dir: Path to sessions directory. Defaults to ~/.augment/sessions/

    Returns:
        Parsed Session object

    Raises:
        FileNotFoundError: If session file doesn't exist
        ValueError: If session JSON is invalid

    """
    directory = sessions_dir if sessions_dir is not None else SESSIONS_DIR
    session_path = directory / f"{session_id}.json"

    if not session_path.exists():
        msg = f"Session not found: {session_id}"
        raise FileNotFoundError(msg)

    with session_path.open() as f:
        data = json.load(f)

    return Session.model_validate(data)


def _try_load(session_id: str, sessions_dir: Path | None) -> Session | None:
    """Attempt to load a session, returning None if invalid."""
    try:
        return load(session_id, sessions_dir)
    except (ValueError, json.JSONDecodeError):
        return None  # Skip invalid sessions, they may be corrupted


def load_all(sessions_dir: Path | None = None) -> list[Session]:
    """
    Load all sessions from the sessions directory.

    Args:
        sessions_dir: Path to sessions directory. Defaults to ~/.augment/sessions/

    Returns:
        List of parsed Session objects (skips invalid sessions)

    """
    return [
        s
        for session_id in list_all(sessions_dir)
        if (s := _try_load(session_id, sessions_dir)) is not None
    ]


# =============================================================================
# CLI Models
# =============================================================================


class ListCmd(BaseModel):
    """List recent sessions."""

    json_output: bool = Field(default=False, alias="json", description="Output as JSON")
    since: int = Field(default=30, description="Days to look back")

    model_config = ConfigDict(populate_by_name=True)


class ShowCmd(BaseModel):
    """Show formatted session log."""

    session_id: str = Field(description="Session ID to display")


class AuglogCLI(BaseModel):
    """Auglog - Session loading and formatting for Augment CLI sessions."""

    list: CliSubCommand[ListCmd]
    show: CliSubCommand[ShowCmd]


# =============================================================================
# CLI Implementation
# =============================================================================


def _run_list(cmd: ListCmd) -> int:
    """Execute list command."""
    sessions = load_all()
    # Filter by date using local timezone for consistency
    cutoff = datetime.now(tz=datetime.now().astimezone().tzinfo).timestamp() - (
        cmd.since * 86400
    )
    recent = [s for s in sessions if s.created.timestamp() > cutoff]
    # Sort by date descending
    recent.sort(key=lambda s: s.created, reverse=True)

    if cmd.json_output:
        output = [
            {
                "id": s.session_id,
                "created": s.created.isoformat(),
                "title": s.title,
                "exchanges": s.exchange_count,
            }
            for s in recent
        ]
        # CLI output is intentional
        print(json.dumps(output, indent=2))  # noqa: T201
    else:
        for s in recent:
            date_str = s.created.strftime("%Y-%m-%d %H:%M")
            # CLI output is intentional
            print(f"{s.session_id[:8]}  {date_str}  {s.title[:60]}")  # noqa: T201

    return 0


def _run_show(cmd: ShowCmd) -> int:
    """Execute show command."""
    # Support partial session ID matching
    session_id = cmd.session_id
    matches = [sid for sid in list_all() if sid.startswith(session_id)]

    if len(matches) == 0:
        # CLI error output is intentional
        print(f"Session not found: {session_id}", file=sys.stderr)  # noqa: T201
        return 1
    if len(matches) > 1:
        # CLI error output is intentional
        print(f"Ambiguous session ID: {session_id}", file=sys.stderr)  # noqa: T201
        for match in matches[:5]:
            print(f"  {match}", file=sys.stderr)  # noqa: T201
        return 1

    try:
        session = load(matches[0])
    except FileNotFoundError:
        # CLI error output is intentional
        print(f"Session not found: {session_id}", file=sys.stderr)  # noqa: T201
        return 1

    # CLI output is intentional
    print(session.format_log())  # noqa: T201
    return 0


def main() -> int:
    """CLI entry point."""
    cli = CliApp.run(AuglogCLI)
    if cli.list:
        return _run_list(cli.list)
    if cli.show:
        return _run_show(cli.show)
    return 0


if __name__ == "__main__":
    sys.exit(main())
