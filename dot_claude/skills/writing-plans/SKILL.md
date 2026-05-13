---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context
for our codebase and questionable taste.
Document everything they need to know:
which files to touch for each task, code, testing, docs they might need to
check, how to test it.
Give them the whole plan as bite-sized tasks.
DRY.
YAGNI.
TDD.
Frequent commits.

**Announce at start:** "I'm using the writing-plans skill to create the
implementation plan."

**Context:** This should be run in a dedicated worktree (created by
brainstorming skill).

## Output Storage

**CRITICAL:** All implementation plans MUST be saved to Basic Memory using
`write_note_basic-memory`.
NEVER use `save-file` or write files to the local filesystem.

**Save plans to:** Basic Memory `artifacts/plans/` directory

```python
write_note_basic - memory(
    title="Plan: <feature-name>",
    content="[plan content]",
    directory="artifacts/plans",
    tags=["plan", "implementation", "<feature-tags>"],
)
```

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**

- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## Task Structure

```markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Step 1: Write the failing test**

[code block with test]

**Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

**Step 3: Write minimal implementation**

[code block with implementation]

**Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

**Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```

```text

## Remember
- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- Reference relevant skills
- DRY, YAGNI, TDD, frequent commits

## Execution Handoff

After saving the plan to Basic Memory, offer execution choice:

**"Plan complete and saved to Basic Memory (`artifacts/plans/<feature-name>`). Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use subagent-driven-development
- Stay in this session
- Fresh subagent per task + code review

**If Parallel Session chosen:**
- Guide them to open new session in worktree
- **REQUIRED SUB-SKILL:** New session uses executing-plans

## Workflow Integration

**Phase:** PLAN

**Inputs:**
- Spec from `artifacts/specs/{feature}` in Basic Memory
- OR exploration notes from `artifacts/explorations/{topic}`

**Outputs:**
- Implementation plan saved to `artifacts/plans/{feature}.md`

**Pre-check:**
Before planning, verify input exists:
- Check Basic Memory for spec or exploration
- If none found: "No spec found. Run EXPLORE phase with `brainstorming` first?"

**Handoff:**
When plan is complete:
1. Save plan to Basic Memory with `write_note_basic-memory`
2. Declare: "**Phase Complete: PLAN -> EXECUTE**"
3. Suggest: "Ready for `executing-plans` or `subagent-driven-development`"

**Related Skills:**
- `brainstorming` - Previous phase (EXPLORE)
- `spec-driven-development` - Alternative if spec well-defined
- `executing-plans` - Next phase (EXECUTE)
- `subagent-driven-development` - Alternative for parallel execution
