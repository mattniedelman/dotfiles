---
description: Full Ralph Wiggum specs-based development flow using subagents
argument-hint: <feature or goal description>
---

# Ralph Wiggum Development Flow

Execute the complete specs-based development workflow using specialized
subagents for each phase.

## The Ralph Wiggum Philosophy

"Don't assume not implemented." Before building anything, understand what
exists.
Specs are source of truth.
Plan is disposable.
One task at a time.

## Model Strategy

| Phase | Agent | Model | Reasoning |
|-------|-------|-------|-----------|
| 1. Specs | **architect** | opus4.5 | Complex requirements analysis |
| 2. Gap Analysis | explore | sonnet4.5 | Searching/comparing - structured |
| 3. Planning | plan | sonnet4.5 | Following template - straightforward |
| 4. Building | implementer | sonnet4.5 | Following plan - TDD |
| 4. Review | code-reviewer | sonnet4.5 | Checking criteria |
| Escalation | **architect** | opus4.5 | When stuck or ambiguous |

## Workflow Phases

```text
Phase 1: Specs        → Define requirements with acceptance criteria (architect)
Phase 2: Gap Analysis → Compare specs vs existing code (explore)
Phase 3: Planning     → Create implementation plan from gaps (plan)
Phase 4: Building     → Execute plan with subagent-per-task + two-stage review
Phase 5: Completion   → Finish branch with verification
```

## Execution

### Phase 1: Spec Creation (architect agent - opus4.5)

First, dispatch explore subagent (sonnet4.5) to gather context:

```text
Explore the codebase to understand:
1. What functionality related to "<topic>" already exists?
2. What patterns, conventions, and structures are used?
3. What would a new feature need to integrate with?

Search thoroughly before reporting. Remember: "Don't assume not implemented."
Report findings as: existing capabilities, patterns to follow, integration points.
```

Then dispatch **architect** subagent (opus4.5) to create specs:

```text
Based on the exploration findings and user goal "<goal>", create spec(s) in specs/ directory.

You have the most capable reasoning. Use it to:
- Identify hidden assumptions and edge cases
- Consider long-term maintainability
- Ask clarifying questions before writing specs

Each spec file (specs/<topic>.md) must have:
- Job to Be Done: what user outcome this enables
- Acceptance Criteria: observable, verifiable outcomes (checkboxes)
- Scope: what's IN and OUT of scope
- Dependencies: other specs or systems needed
- Notes: design decisions and constraints

Topic scope test: can you describe it in one sentence without "and" conjoining unrelated capabilities?
```

### Phase 2: Gap Analysis (sub-agent-explore)

Dispatch explore subagent:

```text
Perform gap analysis for specs in specs/ directory.

For each spec:
1. Read the acceptance criteria carefully
2. Search codebase for existing implementations
3. Compare what's required vs what exists
4. Identify specific gaps (missing, partial, or wrong)

Report: spec-by-spec gap analysis with:
- ✅ Already implemented: [what exists]
- ⚠️ Partial: [what's missing]
- ❌ Missing: [what needs building]
```

### Phase 3: Planning (sub-agent-plan)

Dispatch plan subagent:

```text
Create implementation plan from gap analysis.

Use superpowers:writing-plans skill. Save to docs/plans/YYYY-MM-DD-<feature>.md

Requirements:
- Every task references which spec acceptance criteria it satisfies
- Bite-sized tasks (2-5 minutes each)
- Full TDD: write failing test, verify fail, implement, verify pass, commit
- Exact file paths, complete code, exact commands
- DRY, YAGNI principles

Header must include: "For Claude: REQUIRED SUB-SKILL: Use superpowers:executing-plans"
```

### Phase 4: Building (subagent-driven-development)

Execute plan using subagent-driven-development pattern:

For each task:

1. **Implementer subagent** - implements task, tests, commits, self-reviews
2. **Spec reviewer subagent** - verifies against acceptance criteria
3. **Code quality reviewer subagent** - reviews code quality

Loop until both reviewers approve.
Then next task.

### Phase 5: Completion

Use superpowers:finishing-a-development-branch for final steps.

## Escalation to Architect

Escalate to the **architect** agent (opus4.5) when:

- Requirements are ambiguous or conflicting
- Architecture decisions need deep reasoning
- Implementation gets stuck with unclear path forward
- Specs need revision based on discoveries
- Trade-offs require sophisticated analysis

## Quick Start

When user runs `/ralph <goal>`:

1. **Set up workspace** (if not in worktree):
   - Use superpowers:using-git-worktrees to create isolated workspace

2. **Phase 1:
   Create Specs**
   - Dispatch explore subagent (sonnet4.5) for context
   - Dispatch **architect** subagent (opus4.5) to write specs
   - Validate specs with user

3. **Phase 2:
   Gap Analysis**
   - Dispatch explore subagent (sonnet4.5)
   - Present gaps to user

4. **Phase 3:
   Create Plan**
   - Dispatch plan subagent (sonnet4.5)
   - Save plan to docs/plans/

5. **Phase 4:
   Execute**
   - Use subagent-driven-development for each task
   - Two-stage review (spec compliance, then quality)
   - Escalate to architect if stuck

6. **Phase 5:
   Finish**
   - Run superpowers:finishing-a-development-branch

## User Checkpoints

Pause for user approval at:

- After specs created (Phase 1)
- After gap analysis (Phase 2)
- After plan created (Phase 3)
- After all tasks complete (Phase 5)

## See Also

- `superpowers:spec-driven-development` - Full spec workflow details
- `superpowers:subagent-driven-development` - Task execution pattern
- `superpowers:writing-plans` - Plan creation details
- `superpowers:finishing-a-development-branch` - Branch completion
