#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.augment/hooks
"""
PostToolUse hook: Auto-fix Unicode lookalike characters in file changes.

Works with both Augment CLI and Claude Code via the unified adapter.
Directly modifies files to replace problematic Unicode with ASCII equivalents.
"""

from __future__ import annotations

from pathlib import Path

from augment_adapter import create_unified_context
from cchooks import PostToolUseContext

# Unicode characters: (name, ascii_replacement)
UNICODE_REPLACEMENTS: dict[str, tuple[str, str]] = {
    "\u2014": ("em dash", "-"),
    "\u2013": ("en dash", "-"),
    "\u201c": ("left curly quote", '"'),
    "\u201d": ("right curly quote", '"'),
    "\u2018": ("left single quote", "'"),
    "\u2019": ("right single quote", "'"),
    "\u2026": ("ellipsis", "..."),
    "\u00a0": ("non-breaking space", " "),
    "\u2212": ("minus sign", "-"),
}


def fix_content(content: str) -> tuple[str, list[str]]:
    """
    Replace Unicode lookalikes with ASCII equivalents.

    Returns the fixed content and a list of replacements made.
    """
    fixed = content
    replacements_made = []

    for unicode_char, (name, ascii_replacement) in UNICODE_REPLACEMENTS.items():
        if unicode_char in fixed:
            count = fixed.count(unicode_char)
            fixed = fixed.replace(unicode_char, ascii_replacement)
            replacements_made.append(f"{count}x {name}")

    return fixed, replacements_made


def _get_file_changes(ctx: PostToolUseContext) -> list[dict]:
    """Get file changes from either tool's format."""
    raw = ctx._input_data  # noqa: SLF001

    # Augment format: file_changes array (preserved by adapter)
    file_changes = raw.get("file_changes", [])
    if file_changes:
        return file_changes

    # Claude Code format: tool_response may contain file info
    tool_response = ctx.tool_response
    if "content" in tool_response:
        return [tool_response]

    return []


def main() -> None:
    """Auto-fix Unicode lookalike characters in modified files."""
    ctx = create_unified_context()

    if not isinstance(ctx, PostToolUseContext):
        ctx.output.exit_success()
        return

    file_changes = _get_file_changes(ctx)
    if not file_changes:
        ctx.output.exit_success()
        return

    fixes_applied: list[str] = []

    for change in file_changes:
        file_path = change.get("path", "")
        change_type = change.get("changeType", "")

        # Skip deletions
        if change_type == "delete":
            continue

        # Check if file exists and read current content
        path = Path(file_path)
        if not path.is_file():
            continue

        try:
            content = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue

        fixed_content, replacements = fix_content(content)

        if replacements:
            # Write the fixed content back
            path.write_text(fixed_content, encoding="utf-8")
            fixes_applied.append(f"{file_path}: replaced {', '.join(replacements)}")

    if fixes_applied:
        notice = "ASCII auto-fix applied:\n" + "\n".join(fixes_applied)
        ctx.output.add_context(notice)
    else:
        ctx.output.exit_success()


if __name__ == "__main__":
    main()
