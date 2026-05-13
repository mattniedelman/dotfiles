---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch a code-reviewer subagent to catch issues before they cascade.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**

- After each task in subagent-driven development
- After completing major feature
- Before merge to main

**Optional but valuable:**

- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## How to Request

**1.
Get git SHAs:**

```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2.
Dispatch code-reviewer subagent:**

Use a sub-agent with the code-reviewer template, providing:

**Placeholders:**

- `{WHAT_WAS_IMPLEMENTED}` - What you just built
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit
- `{DESCRIPTION}` - Brief summary

**3.
Act on feedback:**

- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if reviewer is wrong (with reasoning)

## Example

```text
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code-reviewer subagent]
  WHAT_WAS_IMPLEMENTED: Verification and repair functions for conversation index
  PLAN_OR_REQUIREMENTS: Task 2 from docs/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```

## Agent Team Mode: Multi-Perspective Review

When a change spans multiple concerns (security, performance, correctness, test
coverage), use an agent team to run reviewers in parallel with cross-reviewer
discussion.

### When to Use Agent Team Review

- Change touches security-sensitive code AND performance-critical paths
- PR is large (20+ files) and benefits from domain-specific reviewers
- You want reviewers to challenge each other's findings (not just report
  independently)

### When NOT to Use

- Standard single-domain review (subagent is cheaper and sufficient)
- Small PRs with clear scope
- Review where perspectives are orthogonal (no cross-reviewer value)

### The Process

```text
Create an agent team to review [PR/BRANCH]. Spawn 3 reviewers:
- Security reviewer: focus on auth, input validation, secrets, injection
- Performance reviewer: focus on query patterns, memory, concurrency
- Correctness reviewer: focus on logic errors, edge cases, test coverage

Each reviewer should:
1. Review all changed files through their lens
2. Document findings with severity ratings
3. Read other reviewers' findings
4. If another reviewer's recommendation conflicts with your domain
   (e.g., "cache this" creates a security risk), message them directly
5. Produce final findings incorporating cross-reviewer discussion

Wait for all reviewers to finish before synthesizing.
```

The lead synthesizes findings into a single review report, noting where
reviewers agreed, where they conflicted, and how conflicts were resolved.

## Integration with Workflows

**Subagent-Driven Development:**

- Review after EACH task
- Catch issues before they compound
- Fix before moving to next task

**Executing Plans:**

- Review after each batch (3 tasks)
- Get feedback, apply, continue

**Ad-Hoc Development:**

- Review before merge
- Review when stuck

## Red Flags

**Never:**

- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback

**If reviewer wrong:**

- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at:
requesting-code-review/code-reviewer.md
