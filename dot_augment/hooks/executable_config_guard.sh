#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
PreToolUse hook: Block unauthorized config file modifications.

Protects linter configs and quality gate files from modification
without explicit user approval.

From: ECC "config tamper guards" pattern (19-repo analysis)
"""

from __future__ import annotations

import re
from pathlib import Path

from augment_adapter import create_unified_context
from cchooks import PreToolUseContext

PROTECTED_PATTERNS = [
    r"pyproject\.toml$",
    r"\.?ruff\.toml$",
    r"setup\.cfg$",
    r"tox\.ini$",
    r"pytest\.ini$",
    r"\.pre-commit-config\.yaml$",
    r"\.eslintrc",
    r"tsconfig\.json$",
    r"\.prettierrc",
    r"\.markdownlint",
    r"sgconfig\.yml$",
]

COMPILED = [re.compile(p) for p in PROTECTED_PATTERNS]


def is_protected(path: str) -> bool:
    return any(p.search(path) for p in COMPILED)


def get_config_type(path: str) -> str:
    name = Path(path).name.lower()
    if "pyproject" in name:
        return "Python project"
    if "ruff" in name:
        return "Ruff linter"
    if "eslint" in name:
        return "ESLint"
    if "tsconfig" in name:
        return "TypeScript"
    if "markdownlint" in name:
        return "Markdownlint"
    return "Quality gate"


def main() -> None:
    ctx = create_unified_context()
    if not isinstance(ctx, PreToolUseContext):
        ctx.output.exit_success()
        return

    if ctx.tool_name not in ("str-replace-editor", "save-file"):
        ctx.output.allow()
        return

    path = ctx.tool_input.get("path", "")
    if is_protected(path):
        ctx.output.ask(
            f"⚠️ CONFIG MODIFICATION: {path}\n\n"
            f"This {get_config_type(path)} config controls quality gates.\n"
            "Modifying it could disable important checks.\n\n"
            "Allow this modification?"
        )
    else:
        ctx.output.allow()


if __name__ == "__main__":
    main()

