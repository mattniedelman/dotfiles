---
name: ralph
description: Use when executing the full specs-based development workflow - spec creation through brainstorming, gap analysis, planning, and autonomous TDD implementation using specialized subagents
---

# Ralph Development Flow

Execute the complete specs-based development workflow using specialized
subagents.

"Don't assume not implemented." Before building anything, understand what
exists.

## When to Use

- User invokes `/ralph <feature or task description>`
- User wants to build something end-to-end with spec discipline
- User wants autonomous implementation with quality gates

## Workflow

### Phase 1: Spec Creation

1. Dispatch `ralph-explore` agent to gather codebase context
2. Conduct brainstorming directly with user:
   - Share exploration context
   - Ask questions one at a time (purpose, constraints, success criteria)
   - Propose 2-3 approaches with trade-offs
   - Present design incrementally (200-300 words per section)
3. Save spec to Basic Memory with acceptance criteria, scope, dependencies

### Phase 2: Gap Analysis

Dispatch `ralph-explore` agent to compare specs vs existing code.
Present gaps:
already implemented, partial, missing.

### Phase 3: Planning

1. Create a beads epic for the feature:
   `bd create --title="<feature>" --type=epic`
2. Dispatch `ralph-plan` agent to create implementation plan.
   Every task references spec criteria.
   Bite-sized tasks with TDD discipline.
3. Create a beads task per plan task:
   `bd create --title="..." --type=task` Add dependencies as needed:
   `bd dep add <task-id> <epic-id>`

### Phase 4: Building (Autonomous Loop)

Ask:
autonomous or step-by-step?

For each task:

1. `ralph-implement` - implements, tests, commits, self-reviews
2. `ralph-spec-review` - verifies against acceptance criteria
3. `ralph-quality-review` - reviews code quality (after spec passes)

Loop until both reviewers approve, then next task.

**Circuit breaker** (trips only on real stalls):
- No new commits (git HEAD unchanged) for 3 iterations
- Same task reported 3 iterations in a row
- Absolute safety net at 20 iterations

### Phase 5: Completion

1. Verify all tests pass
2. Run linting
3. Present changes summary to user
4. Offer to create PR

## User Checkpoints

Pause for approval at:
after specs, after gap analysis, after plan, after all tasks.

## Escalation

Dispatch `architect` agent when requirements are ambiguous, architecture needs
deep reasoning, or implementation is stuck.
