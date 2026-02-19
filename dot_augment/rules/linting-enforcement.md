---
type: always_apply
priority: HIGH
description: Linting suppression policies and approval workflow
last_updated: 2026-02-19
---

# Linting Enforcement

Linting runs automatically via `auto_lint.sh` hook after every file edit.
See `core-development-rules.md` for enforced patterns.

## Linting Stack (Automated)

| Tool | Location | Purpose |
|------|----------|---------|
| ast-grep | `~/.config/ast-grep/rules/` | Structural patterns (70+ rules) |
| ruff | `~/.config/ruff/ruff.toml` | Style, imports, modern Python |
| pyright/zuban | - | Type checking (preferred over mypy) |

## Fix Priority

1. **ast-grep errors** - MUST fix (structural violations)
2. **ruff errors** - MUST fix (most auto-fixable with `--fix`)
3. **Type errors** - MUST fix
4. **ast-grep warnings** - SHOULD fix

## Suppression Policy

**Default:** Fix errors, don't suppress.

**Suppression requires explicit user approval.** Before adding any suppression:

1. Explain why the error exists and why it's hard to fix
2. Explain consequences of fixing vs suppressing
3. Request explicit permission
4. If approved, use specific rule codes with explanation

## Suppression Syntax

```python
# ✅ Good - specific rule, explanation
LONG_URL = "https://..."  # noqa: E501 - URL cannot be split
result = lib.call()  # type: ignore[no-untyped-call] - missing stubs, issue #123

# ❌ Bad - blanket, no explanation
result = func()  # noqa
result = func()  # type: ignore
```

## Appropriate Suppressions (with approval)

- URLs/literals that can't be split
- Third-party libs with missing/incorrect type stubs
- Generated code that would be overwritten
- Documented false positives

## Never Suppress (always fix)

- Missing type hints
- Unused imports/variables
- Style violations
- Complexity warnings
- Line length in regular code

## Auto-Fix Thresholds

| Count | Action |
|-------|--------|
| 1-20 simple | Auto-fix without asking |
| 21-50 | Inform user, ask permission |
| 51+ | Present options: all, critical only, file-by-file, skip |

**Invasive fixes** (refactoring):
Always ask first.
