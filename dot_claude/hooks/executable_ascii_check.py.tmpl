#!/usr/bin/env -S uv run --quiet --script --directory /home/mattniedelman/.claude/hooks
"""
PostToolUse hook: Auto-fix Unicode lookalike characters in file changes.

Works with both Augment CLI and Claude Code via the unified adapter.
Directly modifies files to replace problematic Unicode with ASCII equivalents.
"""

from __future__ import annotations

import os
from pathlib import Path

from cchooks import PostToolUseContext, PreToolUseContext, create_context

# Get workspace root from Augment environment variable
WORKSPACE_ROOT = Path(os.environ.get("AUGMENT_PROJECT_DIR", ".")).resolve()

# Unicode characters: (name, ascii_replacement)
# Files with integrity checksums that must not be modified
CHECKSUM_PROTECTED_FILES: set[str] = {
    "rtk-rewrite.sh",
}

UNICODE_REPLACEMENTS: dict[str, tuple[str, str]] = {
    # Dashes
    "\u2014": ("em dash", " -- "),  # Spaces added; duplicates cleaned up later
    "\u2013": ("en dash", "-"),
    "\u2212": ("minus sign", "-"),
    # Quotes
    "\u201c": ("left curly quote", '"'),
    "\u201d": ("right curly quote", '"'),
    "\u2018": ("left single quote", "'"),
    "\u2019": ("right single quote", "'"),
    # Ellipsis
    "\u2026": ("ellipsis", "..."),
    # Non-breaking spaces (all variants)
    "\u00a0": ("non-breaking space", " "),
    "\u202f": ("narrow no-break space", " "),
    "\u2007": ("figure space", " "),
    "\u2060": ("word joiner", ""),
    "\ufeff": ("zero-width no-break space/BOM", ""),
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

    # Clean up extra spaces around em-dash replacement only.
    # Em-dash -> " -- " can create "  -- " next to existing spaces.
    # Do NOT use blanket double-space replacement - destroys YAML/Python indentation!
    fixed = fixed.replace("  -- ", " -- ")  # double space before --
    fixed = fixed.replace(" --  ", " -- ")  # double space after --

    return fixed, replacements_made


def _get_file_changes(ctx: PostToolUseContext) -> list[dict]:
    """Get file changes from either tool's format."""
    raw = ctx._input_data  # noqa: SLF001

    # Augment format: file_changes array (preserved by adapter)
    file_changes = raw.get("file_changes", [])
    if file_changes:
        return file_changes

    # Claude Code format: file_path in tool_input (Write, Edit, MultiEdit)
    file_path = ctx.tool_input.get("file_path", "")
    if file_path:
        return [{"path": file_path}]

    return []


def _get_target_file_from_tool_input(ctx: PreToolUseContext) -> Path | None:
    """Extract the target file path from tool input for PreToolUse."""
    tool_input = ctx.tool_input
    # str-replace-editor and save-file use 'path'
    file_path = tool_input.get("path", "")
    if not file_path:
        return None
    path = Path(file_path)
    if not path.is_absolute():
        # Try workspace_roots from context first, then fall back to env var
        raw_data = ctx._input_data  # noqa: SLF001
        workspace_roots = raw_data.get("workspace_roots", [])
        if workspace_roots:
            workspace = Path(workspace_roots[0])
        else:
            workspace = WORKSPACE_ROOT
        path = workspace / file_path
    if path.is_file():
        return path
    return None


def _handle_pre_tool_use(ctx: PreToolUseContext) -> None:
    """Fix Unicode in target file before str-replace-editor reads it."""
    target_file = _get_target_file_from_tool_input(ctx)
    if target_file:
        try:
            content = target_file.read_text(encoding="utf-8")
            fixed_content, replacements = fix_content(content)
            if replacements:
                target_file.write_text(fixed_content, encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            pass  # File unreadable before edit -- skip, hook is best-effort
    ctx.output.exit_success()


def _process_change(change: dict) -> str | None:
    """Apply ASCII fixes to a single changed file; return summary or None."""
    file_path = change.get("path", "")
    change_type = change.get("changeType", "")
    if change_type == "delete" or Path(file_path).name in CHECKSUM_PROTECTED_FILES:
        return None
    path = Path(file_path)
    if not path.is_absolute():
        path = WORKSPACE_ROOT / file_path
    if not path.is_file():
        return None
    try:
        content = path.read_text(encoding="utf-8")
        fixed_content, replacements = fix_content(content)
        if replacements:
            path.write_text(fixed_content, encoding="utf-8")
            return f"{path}: replaced {', '.join(replacements)}"
    except (OSError, UnicodeDecodeError):
        pass  # Unreadable file -- skip silently, hook is best-effort
    return None


def main() -> None:
    """Auto-fix Unicode lookalike characters in modified files."""
    ctx = create_context()

    if isinstance(ctx, PreToolUseContext):
        _handle_pre_tool_use(ctx)
        return

    if not isinstance(ctx, PostToolUseContext):
        ctx.output.exit_success()
        return

    file_changes = _get_file_changes(ctx)
    if not file_changes:
        ctx.output.exit_success()
        return

    fixes_applied = [r for c in file_changes if (r := _process_change(c)) is not None]

    if fixes_applied:
        notice = (
            "ASCII auto-fix applied (Unicode replaced with ASCII equivalents):\n"
            + "\n".join(fixes_applied)
            + "\n\nDo NOT acknowledge this. Resume your task silently."
        )
        ctx.output.add_context(notice)
    else:
        ctx.output.exit_success()


if __name__ == "__main__":
    main()
