---
type: always_apply
priority: HIGH
description: Specs-based development workflow inspired by the Ralph Wiggum technique
last_updated: 2025-01-27
---

# Specs-Based Development

## Overview

**Rule**: When working in any git repository, treat it as a project and apply specs-based development. This workflow ensures implementation aligns with requirements and is inspired by the Ralph Wiggum technique, adapted for interactive development.

## Activation

This workflow is **automatically active** when:
- The workspace is a git repository
- A `specs/` directory exists, OR
- The user requests spec-related work ("create spec", "plan", "gap analysis", etc.)

**Session Start Behavior**: When entering a git repository, check for:
1. Existing `specs/*.md` files - read to understand requirements
2. Existing `IMPLEMENTATION_PLAN.md` - read to understand current state
3. Basic-memory notes about this project - consult for context

## Key Principle: Don't Assume Not Implemented

**CRITICAL**: Before implementing ANY functionality, search the codebase to confirm it doesn't already exist. This is the most common failure mode - duplicating or conflicting with existing code.

## Project Structure

Projects using specs-based development should have:

```
project-root/
├── specs/                    # Requirement specifications
│   ├── [topic-a].md         # One file per topic of concern
│   └── [topic-b].md
├── IMPLEMENTATION_PLAN.md    # Prioritized task list (optional)
└── src/                      # Implementation
```

## Specs Format

Each spec file (`specs/*.md`) should define ONE topic of concern:

```markdown
# [Topic Name]

## Job to Be Done
What user outcome does this enable?

## Acceptance Criteria
Observable, verifiable outcomes that indicate success:
- [ ] Criterion 1 (behavioral, not implementation-specific)
- [ ] Criterion 2
- [ ] Criterion 3

## Scope
What is IN scope and OUT of scope for this topic.

## Dependencies
Other specs or systems this depends on.

## Notes
Design decisions, constraints, or context.
```

### Topic Scope Test

Can you describe the topic in one sentence without "and" conjoining unrelated capabilities?
- ✅ "The color extraction system analyzes images to identify dominant colors"
- ❌ "The user system handles authentication, profiles, and billing" → 3 topics

## Workflow Phases

### Phase 1: Define Requirements (Human + AI Conversation)

1. Discuss project goals and identify Jobs to Be Done (JTBD)
2. Break each JTBD into topics of concern
3. For each topic, create `specs/[topic].md` with acceptance criteria
4. Keep criteria behavioral (outcomes), not implementation-specific

**AI Role**: Help clarify requirements, identify edge cases, suggest acceptance criteria. Ask probing questions before writing specs.

### Phase 2: Planning (Gap Analysis)

1. Study all specs in `specs/*`
2. Search codebase to understand current state ("don't assume not implemented")
3. Compare specs against existing code
4. Create/update `IMPLEMENTATION_PLAN.md` with prioritized tasks

**AI Role**: Perform gap analysis, identify what's missing, prioritize tasks. Do NOT implement during planning.

### Phase 3: Building (Implement from Plan)

1. Select highest-priority task from plan
2. Search codebase before implementing (confirm not already done)
3. Implement functionality per spec
4. Run tests (backpressure)
5. Update plan: mark complete, note discoveries
6. Commit when tests pass

**AI Role**: Implement one task at a time, validate against acceptance criteria, update plan.

## Commands

The user may invoke these modes explicitly:

| Command | Action |
|---------|--------|
| "create spec for [topic]" | Create `specs/[topic].md` with template |
| "plan" or "gap analysis" | Compare specs vs code, update IMPLEMENTATION_PLAN.md |
| "build from plan" | Implement next priority task from plan |
| "check spec [topic]" | Verify implementation against spec's acceptance criteria |

## Integration with Basic-Memory

- Store project specs context in basic-memory for cross-session continuity
- When starting a session, check for existing specs and plans
- Update notes when specs evolve or significant decisions are made

## Backpressure

Implementation is validated by:
1. **Tests** - Required tests derived from acceptance criteria must pass
2. **Type checks** - mypy must pass
3. **Linting** - ruff and ast-grep must pass

If backpressure fails, fix before proceeding. Do not mark tasks complete until validation passes.

### When Validation Method Is Unclear

**Rule**: If the appropriate validation method is not obvious, ASK before proceeding.

Examples of unclear validation:
- No existing test suite or unclear test patterns
- Acceptance criteria that resist programmatic validation (UX, aesthetics, tone)
- Infrastructure changes where "success" is ambiguous
- Integration points with external systems
- Performance requirements without defined benchmarks

**Ask**: "How should I validate this? Options: [suggest relevant options based on context]"

## Guardrails

1. **One task at a time** - Complete and validate before moving to next
2. **Search before implementing** - Always confirm functionality doesn't exist
3. **Specs are source of truth** - Implementation must satisfy acceptance criteria
4. **Plan is disposable** - Regenerate if wrong or stale
5. **Capture the why** - Document reasoning in specs and notes, not just what

## When Specs Are Required vs Optional

**Specs required** (create before implementing):
- New features with multiple components
- Refactoring with clear target state
- Work spanning multiple sessions
- Any work where acceptance criteria would clarify success

**Specs optional** (proceed directly):
- Quick fixes or single-file changes
- Bug fixes with obvious solutions
- Exploratory/investigative work
- Changes explicitly scoped by user in the request

**When in doubt**: Ask "Should I create a spec for this, or proceed directly?"

