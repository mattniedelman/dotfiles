---
name: step-through
description: Use when user wants to go through output incrementally - walk through items one at a time with pause between each, progressive disclosure for long outputs
---

# Step Through

Progressive disclosure for long outputs.
Present items one at a time, pausing for user confirmation before continuing.

## Triggers

- `/step` or `/step through`
- "walk me through"
- "one at a time"
- "step by step"
- "go through each"

## Behavior

When stepping mode is activated:

1. **Acknowledge** stepping mode with item count
2. **Present first item** with clear formatting
3. **Wait** for user input before next item
4. **Respond** to navigation commands

## Navigation Commands

| User Says | Action |
|-----------|--------|
| `next`, `n`, `continue` | Show next item |
| `skip`, `s` | Skip current, show next |
| `back`, `b`, `previous` | Show previous item |
| `all`, `a`, `show all` | Dump all remaining items |
| `stop`, `done`, `quit` | Exit stepping mode |
| `repeat` | Show current item again |
| Number (e.g., `3`) | Jump to that item |

## Item Presentation Format

```markdown
## Item [N] of [Total]

[Item content - formatted appropriately for type]

---
**Navigation:** [next] [skip] [all] [stop]
**Position:** [N]/[Total] | [remaining] remaining
```

## Example Flow

**User:** `/step through the lint errors`

**Agent:**

> Found **5 lint errors**. Showing in stepping mode.
>
> **Error 1 of 5**
>
> **File:** `src/auth.py:42` | **Rule:** `no-ternary-expression`
>
> `status = "active" if user.is_active else "inactive"`
>
> **Fix:** Use explicit if/else block
>
> ---
>
> **Navigation:** [next] [skip] [all] [stop]

**User:** `next`

**Agent:**

> **Error 2 of 5**
>
> **File:** `src/config.py:67` | **Rule:** `magic-number`
>
> `if retry_count > 3:`
>
> **Fix:** Use named constant or configuration
>
> ---
>
> **Navigation:** [next] [skip] [all] [stop] | **Position:** 2/5 | 3 remaining

**User:** `all`

**Agent:**

> Showing remaining 3 errors:
>
> **Error 3:** [...] | **Error 4:** [...] | **Error 5:** [...]
>
> ---
>
> ✓ All 5 items shown. Stepping complete.

## Applicable Content Types

Step-through works well for:

| Content Type | Per-Item Format |
|--------------|-----------------|
| Lint errors | File, line, rule, snippet, fix |
| Test failures | Test name, assertion, expected vs actual |
| Search results | File, match context, relevance |
| Recommendations | Title, evidence, action |
| Files in directory | Name, size, purpose |
| Git commits | Hash, message, files changed |
| API endpoints | Method, path, description |

## When NOT to Use

- Single items (just show it)
- Highly interconnected content (context needed)
- When user explicitly asks for "all" or "full"
- Time-sensitive operations

## State Management

Track during stepping:

- `items`:
  list of items to present
- `current_index`:
  position in list
- `total_count`:
  len(items)
- `history`:
  items already shown (for back navigation)

Reset state when:

- User says "stop" or "done"
- All items shown
- New unrelated request
- Session ends

## Combining with Other Skills

| Skill | Example |
|-------|---------|
| lint-workflow | `/step through lint errors` → fix each as you go |
| codebase-retrieval | `/step through search results` → investigate relevant ones |
| git-workflow | `/step through recent commits` → review changes |
