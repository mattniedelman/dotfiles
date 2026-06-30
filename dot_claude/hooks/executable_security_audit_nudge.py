#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.claude/hooks
# /// script
# dependencies = ["cchooks"]
# ///
"""
PostToolUse hook: Nudge toward the right security auditor at the right moment.

Two deterministic triggers:
  1. A dependency-adding Bash command (uv add, npm install <pkg>, poetry add,
     cargo add, go get, pip install ...) -> nudge supply-chain-risk-auditor.
     This watches the COMMAND, not the manifest file, because `uv add` mutates
     pyproject.toml via Bash -- a file-edit hook would miss it.
  2. An edit to a GitHub Actions workflow that invokes an AI coding agent
     -> nudge agentic-actions-auditor. Pre-filtered: only fires when the
     workflow actually references an AI agent action, to avoid noise.

These are nudges (injected reminders), not auto-runs: the auditors are
LLM-judgment skills, not one-shot CLIs, so a hook cannot execute them.
"""

from __future__ import annotations

import re
from pathlib import Path

from cchooks import PostToolUseContext, create_context

# Dependency-adding commands at a command boundary. Captures the ecosystem so
# the nudge can name the right manifest. Deliberately narrow: only commands that
# ADD a new dependency (not lockfile syncs like `uv sync` or `npm ci`).
ADD_DEP_RE = re.compile(
    r"""
    (?:^|[;&|`(])\s*
    (?:
        uv\s+add                       # uv add [--dev] <pkg>
        | poetry\s+add
        | pdm\s+add
        | pipenv\s+install
        | pip3?\s+install\s+(?!-r\b)   # pip install <pkg> (not -r requirements)
        | npm\s+install\s+(?!$)        # npm install <pkg> (bare `npm install` = sync)
        | npm\s+i\s+(?!$)
        | pnpm\s+add
        | yarn\s+add
        | bun\s+add
        | cargo\s+add
        | go\s+get
    )
    """,
    re.VERBOSE,
)

# Opening a PR -- the moment to run a security-focused differential review.
# Matches `gh pr create` at a command boundary; ignores `gh pr view/list/diff`.
GH_PR_CREATE_RE = re.compile(
    r"(?:^|[;&|`(])\s*gh\s+pr\s+create\b",
)

# AI-agent action references inside a GitHub Actions workflow.
AI_AGENT_WORKFLOW_RE = re.compile(
    r"anthropics/claude-code-action"
    r"|claude-code"
    r"|google-github-actions/run-gemini"
    r"|gemini-cli"
    r"|openai/codex"
    r"|github/ai-inference",
    re.IGNORECASE,
)

WORKFLOW_PATH_RE = re.compile(r"/\.github/workflows/[^/]+\.ya?ml$")

DEP_NUDGE = (
    "You just added a dependency. Before relying on it, consider running the "
    "`supply-chain-risk-auditor` skill on the affected manifest to check the new "
    "package's maintainer health, abandonment, and takeover risk -- especially "
    "for AI/MCP/agent libraries, where single-maintainer and young packages are "
    "the live attack surface. Skip only if this is a well-known, vetted dependency."
)

WORKFLOW_NUDGE = (
    "You edited a GitHub Actions workflow that invokes an AI coding agent. Run the "
    "`agentic-actions-auditor` skill on it -- it detects prompt-injection paths "
    "from attacker-controlled input (issue/PR bodies, comments, pull_request_target) "
    "and dangerous sandbox/allowlist configs. This maps directly to AI-tool "
    "supply-chain controls."
)

PR_CREATE_NUDGE = (
    "You just opened a PR. If the diff touches security-relevant code (auth, input "
    "validation, crypto, external/LLM calls, secrets, or access control), run the "
    "`differential-review` skill on it -- it risk-classifies changed files, uses git "
    "history to catch security regressions (removed validation, dropped access checks), "
    "and can model exploit scenarios for high-risk changes. Skip for docs/config-only PRs."
)


def main() -> None:
    """Inject a security-audit nudge when a triggering event is detected."""
    ctx = create_context()
    if not isinstance(ctx, PostToolUseContext):
        ctx.output.exit_success()
        return

    tool_input = ctx.tool_input or {}

    # Triggers 1 & 3: dependency-adding command, or opening a PR
    if ctx.tool_name == "Bash":
        command = tool_input.get("command", "")
        if command and ADD_DEP_RE.search(command):
            ctx.output.add_context(DEP_NUDGE)
            return
        if command and GH_PR_CREATE_RE.search(command):
            ctx.output.add_context(PR_CREATE_NUDGE)
            return
        ctx.output.exit_success()
        return

    # Trigger 2: edit to an AI-agent GitHub Actions workflow
    if ctx.tool_name in ("Edit", "Write"):
        file_path = tool_input.get("file_path", "")
        if file_path and WORKFLOW_PATH_RE.search(file_path):
            path = Path(file_path)
            try:
                content = path.read_text(encoding="utf-8") if path.is_file() else ""
            except OSError:
                content = ""
            if content and AI_AGENT_WORKFLOW_RE.search(content):
                ctx.output.add_context(WORKFLOW_NUDGE)
                return
        ctx.output.exit_success()
        return

    ctx.output.exit_success()


if __name__ == "__main__":
    main()

# vim: set ft=python:
