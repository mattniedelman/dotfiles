#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.claude/hooks
"""
PreToolUse hook (Bash): Block raw `pip` invocations and steer to `uv add`.

Policy:
  - Never run raw pip (pip, pip3, python -m pip, python3 -m pip, etc.) -> deny
  - Prefer `uv add <pkg>` for project dependencies
  - `uv pip install` is discouraged (ask) -- last resort for ad-hoc envs

`uv pip ...` is NOT a raw pip invocation (uv runs its own resolver) and is
not blocked by the raw-pip check; it is intercepted separately with an
"ask" decision to nudge toward `uv add`.
"""

from __future__ import annotations

import re

from cchooks import create_context
from cchooks import PreToolUseContext

# Matches raw pip at a command boundary. Boundaries: start-of-string, or after
# `;`, `&&`, `||`, `|`, `&`, backtick, `$(`, `(`. Optional leading `sudo`.
# Captures:
#   pip, pip2, pip3
#   python -m pip, python3 -m pip, py -m pip
# Explicitly does NOT match `uv pip ...` because `uv ` precedes `pip` without
# a boundary token between them.
RAW_PIP_RE = re.compile(
    r"""
    (?:^|[;&|`(])                 # command boundary
    \s*
    (?:sudo\s+)?                  # optional sudo
    (?:
        (?:python3?|py)\s+-m\s+pip   # python -m pip forms
        |
        pip[23]?                     # pip / pip2 / pip3
    )
    (?:\s|$|[;&|)])               # followed by whitespace, end, or boundary
    """,
    re.VERBOSE,
)

UV_PIP_INSTALL_RE = re.compile(
    r"(?:^|[;&|`(])\s*uv\s+pip\s+install(?:\s|$)",
)

DENY_REASON = (
    "Raw pip is blocked. Use uv instead:\n"
    "  - Add dep:      uv add <package>           (preferred; updates "
    "pyproject.toml + uv.lock)\n"
    "  - Add dev dep:  uv add --dev <package>\n"
    "  - Remove:       uv remove <package>\n"
    "  - Run script:   uv run <cmd>\n"
    "  - Install tool: uv tool install <package>\n"
    "  - Last resort:  uv pip install <package>   (ad-hoc envs only; "
    "prefer uv add)\n"
    "If the project is not uv-managed yet, run `uv init` first."
)

ASK_REASON = (
    "Prefer `uv add <package>` over `uv pip install <package>` for project "
    "dependencies -- `uv add` updates pyproject.toml and uv.lock so the "
    "dependency is tracked. Only use `uv pip install` for ad-hoc virtualenvs "
    "or when `uv add` does not apply (e.g., editable installs into an "
    "unmanaged venv). Confirm this is one of those cases."
)


def main() -> None:
    ctx = create_context()

    if not isinstance(ctx, PreToolUseContext):
        ctx.output.exit_success()
        return

    if ctx.tool_name != "Bash":
        ctx.output.allow()
        return

    command = (ctx.tool_input or {}).get("command", "")
    if not command:
        ctx.output.allow()
        return

    if RAW_PIP_RE.search(command):
        ctx.output.deny(reason=DENY_REASON)
        return

    if UV_PIP_INSTALL_RE.search(command):
        ctx.output.ask(reason=ASK_REASON)
        return

    ctx.output.allow()


if __name__ == "__main__":
    main()
