#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
PreToolUse hook: Enforce semantic search for code symbols.

Warns when grep/ripgrep is used for what looks like code symbol searches.
Suggests find_symbol, find_referencing_symbols, or codebase-retrieval.

From: core-development-rules "Tool Selection Hierarchy" (19-repo analysis)
"""

from __future__ import annotations

import re

from augment_adapter import create_unified_context
from cchooks import PreToolUseContext

SYMBOL_PATTERNS = [
    r"\b(class|def|function|const|interface|struct|enum)\s+\w+",
    r"\b[A-Z][a-z]+(?:[A-Z][a-z]+)+\b",  # CamelCase
    r"\b(get|set|create|update|delete|find|fetch|handle)_\w+",  # snake_case functions
]

COMPILED = [re.compile(p) for p in SYMBOL_PATTERNS]
TEXT_SEARCH = ["grep", "rg", "ripgrep", "ag", "ack"]


def is_text_search(command: str) -> bool:
    cmd = command.lower()
    return any(f" {t} " in f" {cmd} " or cmd.startswith(f"{t} ") for t in TEXT_SEARCH)


def looks_like_symbol_search(command: str) -> bool:
    return any(p.search(command) for p in COMPILED)


def main() -> None:
    ctx = create_unified_context()
    if not isinstance(ctx, PreToolUseContext):
        ctx.output.exit_success()
        return

    if ctx.tool_name != "launch-process":
        ctx.output.allow()
        return

    command = ctx.tool_input.get("command", "")
    if is_text_search(command) and looks_like_symbol_search(command):
        ctx.output.allow(
            reason=(
                "⚠️ SEARCH STRATEGY: Text search for possible code symbol.\n\n"
                "For code symbols, prefer:\n"
                "- find_symbol_serena -- definitions\n"
                "- find_referencing_symbols_serena -- usages\n"
                "- codebase-retrieval -- conceptual search\n\n"
                "grep/rg is best for: config files, string literals, comments.\n"
                "Proceeding, but consider semantic tools for better accuracy."
            )
        )
    else:
        ctx.output.allow()


if __name__ == "__main__":
    main()

