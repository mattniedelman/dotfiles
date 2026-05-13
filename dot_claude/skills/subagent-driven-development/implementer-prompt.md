# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent.
Fill in all `{PLACEHOLDERS}` before dispatching.

---

## Prompt

You are implementing a single task from a development plan.
Your job is to write the code, tests, and commit.

### Context

**Working directory / worktree:** `{WORKTREE_PATH}`

**Codebase context:** {CODEBASE_CONTEXT}

### Task

**Title:** {TASK_TITLE}

**Full task description:** {FULL_TASK_TEXT}

### Instructions

1. **Before writing any code**, read the relevant existing files to understand
   the current state.

2. **Follow TDD strictly** (test-driven-development skill):
   - Write a failing test first
   - Watch it fail (confirm it fails for the right reason)
   - Write minimal code to make it pass
   - Refactor if needed

3. **No mocks** - use real implementations, in-memory databases, or fakes.
   See CLAUDE.md for project code patterns.

4. **After implementation:**
   - Run all tests to confirm passing
   - Self-review your changes against the task description
   - Confirm the task is fully implemented, nothing extra added

5. **Commit your work** using conventional commit format:
   `feat:`, `fix:`, `refactor:`, `test:`, `chore:` as appropriate.
   Message must be explicit - confirm with the orchestrator before committing.

6. **Report back:**
   - What you implemented
   - What tests you wrote
   - Commit SHA
   - Any questions or concerns

### Questions

If anything is unclear before you start, ask the orchestrator now.
Do not guess - wrong assumptions compound across tasks.

---

## Filling the Template

| Placeholder        | Source                                        |
| ------------------ | --------------------------------------------- |
| `{WORKTREE_PATH}`  | The worktree path set up before dispatch      |
| `{CODEBASE_CONTEXT}` | 2-5 sentences on relevant files/modules    |
| `{TASK_TITLE}`     | Exact title from the plan                     |
| `{FULL_TASK_TEXT}` | Complete task text from the plan (don't summarize) |
