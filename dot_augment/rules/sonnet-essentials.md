---
type: always_apply
priority: CRITICAL
description: Compressed critical rules optimized for Sonnet - read first
---

# Sonnet Quick Reference

## BEFORE EVERY RESPONSE

Complete this checklist:

- [ ] 1.
  Skill might apply?
  → Read it first
- [ ] 2.
  Searching for code?
  → Use find_symbol (NEVER grep)
- [ ] 3.
  Git operation?
  → Use MCP tools (NEVER launch-process)
- [ ] 4.
  Claiming "done"?
  → Run verification first
- [ ] 5.
  Failed 2x similarly?
  → STOP, reassess

## Tool Selection (No Exceptions)

| Target | Use | Never Use |
|--------|-----|-----------|
| Code symbol (class/function/variable) | find_symbol | grep, ripgrep |
| Symbol usages/references | find_referencing_symbols | grep |
| "How does X work" | codebase-retrieval | - |
| Text in specific file | view with search_query_regex | - |
| Config/YAML/JSON | grep, ripgrep | - |

**Decision:** IF target is class, function, method, or variable → semantic
tools.
ELSE → text search is OK.

## Git Operations (MCP Tools Only)

| Action | Tool |
|--------|------|
| Status | git_status_git |
| Stage files | git_add_git (list SPECIFIC files, NEVER all:true) |
| Commit | git_commit_git (requires user permission in main checkout) |
| Diff | git_diff_git |
| Log | git_log_git |

**BLOCKED:** `launch-process` with any git command.

## Loop Detection

| After This Many Failures | Action |
|--------------------------|--------|
| 2 similar attempts | Pause, state what's not working |
| 3 similar attempts | STOP, ask user for help |

**Signs of a loop:**

- Same tool with similar arguments
- Same error message appearing
- Same file edit failing

**When detected:** Say "I notice I'm repeating X.
This isn't working.
Let me try a different approach or ask for help."

## Verification (Before Claiming Done)

1. Run test command
2. See output in response
3. Confirm:
   "X tests passed" or "0 failures"
4. ONLY THEN claim success

**PROHIBITED words without evidence:**

- "should work"
- "looks good"
- "probably passes"
- "I believe this fixes"

**REQUIRED format:**

```text
✅ pytest output: 34/34 passed
✅ ruff: 0 errors
✅ Tests pass, lint clean
```

## Response Style

**NEVER say:**

- "Great question"
- "Excellent"
- "I'm happy to"
- "Good catch"
- "That's interesting"

**ALWAYS:** Start directly with technical content.

## Code Patterns (Enforced by Linters)

**Never use:**

- Nested functions (functions inside functions)
- `continue` statements
- Mocks (`unittest.mock`, `pytest-mock`, `monkeypatch`)
- `dataclasses` (use Pydantic)
- `os.path` (use pathlib)
- Legacy typing (`List`, `Optional`) - use `list`, `X | None`

## Git Authorization Quick Reference

| Location | Commit Permission |
|----------|-------------------|
| `.worktrees/` directory | ALLOWED - commit freely |
| Main checkout | EXPLICIT - user must say "commit" |

**Phrases that do NOT authorize commit:**

- "save my work"
- "finish this"
- "complete the task"

## Phase Declaration

State your phase before significant work:

```text
**Phase: EXPLORE** - Understanding the codebase
**Phase: PLAN** - Creating implementation steps
**Phase: EXECUTE** - Writing code
**Phase: VERIFY** - Running tests and linters
**Phase: LEARN** - Capturing to Basic Memory
```

## Quick Skill Reference

| Situation | Skill to Use |
|-----------|--------------|
| Starting work | using-superpowers |
| Debugging | systematic-debugging |
| Before claiming done | verification-before-completion |
| Writing tests | test-driven-development |
| Capturing decisions | knowledge-capture |
| Resuming work | continue-conversation |
