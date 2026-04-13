---
name: document-generation
description: Use when generating markdown documents, reports, specs, or prose content - provides workflow to avoid formatting struggles and linting loops
---

# Document Generation

Generate markdown documents cleanly without the view->edit->lint->fix loop.

## Key Insight

The 150-line guidance for code files does not apply to prose:

| Concern | Code | Prose/Markdown |
|---------|------|----------------|
| Incremental verification | Critical - errors compound | Less relevant - auto-fix handles formatting |
| Hidden errors | One wrong char breaks things | Formatting is cosmetic |
| Build process | Each step should lint | Only final result matters |

**For markdown:
write complete content with `Write`, let the hook auto-fix formatting.**

## Workflow

```text
1. Write (full content, any length)
2. Hook runs markdownlint --fix automatically
3. Review any remaining errors (rare)
```

That's it.
The `auto_lint.sh` hook handles formatting automatically.

## What the Hook Does

On every markdown file modification:

1. **mdsf** - Code block formatting (ruff for Python, shfmt for bash, prettier
   for JS/TS, etc.)
2. **mdslw** - Semantic line wrapping of prose
3. **markdownlint --fix** - Auto-fixes ~90% of formatting issues
4. **markdownlint** - Reports remaining unfixable errors
5. **lychee** - Wiki-link validation (Basic Memory only)

The mdsf tool formats code blocks using language-specific formatters configured
in `~/.config/mdsf/mdsf.json`.

## Prevention: Avoid Unfixable Issues

The auto-fixer handles formatting, but some issues require manual attention.
Avoid these during generation:

### Line Breaks That Create False List Items

```markdown
Wrong - the + at line start looks like a list item:
**Total:** 1 + 2 +
3 + 4 = 10

Right - keep expressions on one line:
**Total:** 1 + 2 + 3 + 4 = 10
```

### Missing Language Specifiers

````markdown
Wrong:
```
def foo():
    pass
```

Right:
```python
def foo():
    pass
```
````

### Inconsistent Table Column Counts

```markdown
Wrong - row 2 has 2 columns, header has 3:
| A | B | C |
|---|---|---|
| 1 | 2 |

Right:
| A | B | C |
|---|---|---|
| 1 | 2 | 3 |
```

## Tool Selection

| Scenario | Approach |
|----------|----------|
| Any markdown file | Use `Write` with full content |
| Appending sections | Use `Edit` insert |
| Fixing content issues | Use `Edit` (for content, not formatting) |
| Fixing formatting issues | Don't - let the hook handle it |

## What NOT to Do

| Anti-pattern | Why It's Wrong | Instead |
|--------------|----------------|---------|
| Manual blank line fixes | Hook does this automatically | Wait for hook |
| `Edit` for formatting | Wrong tool for prose | Let hook auto-fix |
| Multiple small writes | Creates boundary issues | Write complete content |
| Running markdownlint manually | Hook already runs it | Trust the hook |
| Chunking to stay under 150 lines | Guidance is for code, not prose | Write full content |

## When Manual Intervention Is Needed

The hook reports errors it can't auto-fix.
These are typically:

- **Content issues** (wrong info, missing sections)
- **Structural issues** (heading hierarchy, duplicate headings)
- **Code block language detection failures**

For these, use `Edit` to fix the **content**, not the formatting.

## Planning & Best Practices

### Outline First (for complex documents)

For documents with multiple sections, sketch an outline before writing:

```text
1. Think through the structure (sections, flow)
2. Optionally share outline with user for approval
3. Then write full content
```

This catches structural issues before you've written 500 lines.
Skip for simple documents (README, single-topic notes).

### Test Code Examples

If your document includes code examples readers will copy/paste, **test them
before including**.
Broken examples erode trust faster than any other documentation failure.

For code-heavy documents (tutorials, API docs), consider running examples
through a syntax checker or actually executing them.

### Split Large Documents

For documents over 500 lines, consider:

- Splitting into separate files by topic
- Creating an index/overview document with links
- Using consistent naming (`topic-overview.md`, `topic-details.md`)

This aids navigation and makes updates easier.

## Example: Report Generation

```text
User: "Create a performance analysis report"

1. Gather information (Grep, Read, etc.)
2. Write full report content with Write (any length)
3. Hook auto-fixes formatting
4. If errors remain: fix content issues with Edit
5. Done
```

This replaces the old pattern of:
write 150 lines -> lint fails -> fix -> lint -> fix -> ...
(15+ cycles)
