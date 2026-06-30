---
name: ralph
description: Specs-based feature development with TDD -- build, implement, develop a feature end-to-end with spec creation, gap analysis, planning, and autonomous implementation using specialized subagents. Use for new features, significant changes, and any work that needs spec discipline and quality gates.
allowed-tools: Agent, Bash(br:*), Bash(git:*), mcp__basic-memory__write_note, mcp__basic-memory__read_note, mcp__basic-memory__search_notes, mcp__semble__search, mcp__semble__find_related
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
- User wants full TDD discipline with spec and quality review gates on a non-trivial feature

## When NOT to Use

- **Single-file or trivial changes** -- a one-function fix or typo correction; use `/implement` directly
- **Exploratory spikes** -- no defined acceptance criteria yet; brainstorm first, then return to ralph
- **Hotfixes** -- urgent production fixes that cannot wait for spec/plan overhead; fix directly then file a follow-up spec
- **Work already in-flight** -- a plan and beads tasks already exist; resume from Phase 4 rather than restarting from Phase 1

## Workflow

**For per-agent dispatch briefs and the spec template, see `agents.md`** -- it
has a scoped brief for each of the five subagents (`ralph-explore`,
`ralph-plan`, `ralph-implement`, `ralph-spec-review`, `ralph-quality-review`)
and a worked spec template (acceptance-criteria / scope / dependencies). Use
those briefs when constructing each dispatch prompt below.

### Phase 1: Spec Creation

1. Dispatch `ralph-explore` agent to gather codebase context
2. Conduct brainstorming directly with user:
   - Share exploration context
   - Ask questions one at a time (purpose, constraints, success criteria)
   - Propose 2-3 approaches with trade-offs
   - Present design incrementally (200-300 words per section)
3. Save spec to Basic Memory with acceptance criteria, scope, dependencies

**Exit criteria:** Spec saved to Basic Memory and user has approved it at the checkpoint.

### Phase 2: Gap Analysis

Dispatch `ralph-explore` agent to compare specs vs existing code.
Present gaps: already implemented, partial, missing.

**Exit criteria:** Every acceptance criterion classified (implemented / partial / missing) and user has approved the gap list at the checkpoint.

### Phase 3: Planning

1. Create a beads epic for the feature:
   `br create "<feature>" --type epic`
2. Dispatch `ralph-plan` agent to create implementation plan.
   Every task references spec criteria.
   Bite-sized tasks with TDD discipline.
3. Create a beads task per plan task:
   `br create "..." --type task` Add dependencies as needed:
   `br dep add <task-id> <epic-id>`

**Exit criteria:** Plan saved to Basic Memory, all beads tasks created, and user has approved the plan at the checkpoint.

### Phase 4: Building (Autonomous Loop)

Ask: autonomous or step-by-step?

For each task:

1. `ralph-implement` - implements, tests (full suite must pass), commits, self-reviews
2. `ralph-spec-review` - verifies against acceptance criteria; if FAIL, route back to step 1 for the same task
3. `ralph-quality-review` - reviews code quality; if FAIL on Critical issues, route back to step 1; Important/Minor issues may proceed at user discretion

Loop until spec-review PASS and quality-review PASS (or user approves proceeding on non-Critical issues), then advance to the next task.

**Circuit breaker** (trips only on real stalls):
- No new commits (`git rev-parse HEAD` unchanged) for 3 iterations
- Same task reported 3 iterations in a row
- Absolute safety net at 20 iterations

### Phase 5: Completion

1. Run the full test suite -- if anything fails, route back to Phase 4 as a new iteration before presenting results
2. Run linting -- surface any errors to the user before the summary
3. Present changes summary to user, including final test count and lint status
4. Offer to create PR

**Exit criteria:** Full test suite green, lint clean, summary presented, user has accepted or declined PR offer. Close all beads tasks for this epic.

## User Checkpoints

Pause for approval at:
after specs, after gap analysis, after plan, after all tasks.

## Escalation

Dispatch `architect` agent when requirements are ambiguous, architecture needs
deep reasoning, or implementation is stuck.
