---
name: beads-workflow
description: Use when working in a project with beads (bd) issue tracking -- dependency modeling, decision gates, discovered-from links, sub-agent dispatch, and Basic Memory integration
---

# Beads Workflow Patterns

Judgment calls and workflow patterns for beads issue tracking that agents get
wrong without guidance.
This skill covers *how to think about* beads, not how to use the CLI or MCP
tools.

## Quick Reference

| Pattern | When | Key Command |
|---------|------|-------------|
| Decision gate | Architectural question blocks 2+ tasks | `create -t decision`, deps point to it |
| Discovered-from | Found new work during implementation | `--deps discovered-from:<parent>` |
| Sub-agent dispatch | 2+ ready issues are independent | `bd ready` → claim → dispatch |
| Basic Memory link | Decision resolved or captured | `external_ref` ↔ BM note |
| Compaction | Phase complete, old issues are noise | `bd admin compact --days N` |
| Label routing | Different agent types for different work | `bd ready --labels <category>` |

## Dependency Type Selection

This is the most common source of agent errors.
Use this decision tree:

**"Must A finish before B can start?"**

- Yes → `blocks` (A blocks B)
- No → continue

**"Is B a subtask of A?"**

- Yes → `parent-child` (organizational grouping only)
- No → continue

**"Did I discover B while working on A?"**

- Yes → `discovered-from` (B discovered-from A)
- No → `related`

**IMPORTANT:
`parent-child`, `discovered-from`, and `blocks` are ALL orthogonal.** An issue
can have multiple link types simultaneously.
Only `blocks` affects `bd ready`.
The others are metadata:

- `parent-child` tracks *organizational grouping* (epic/subtask)
- `discovered-from` tracks *why the issue exists* (provenance)
- `blocks` tracks *what it prevents* (sequencing)

**CRITICAL:
`parent-child` does NOT block anything.** Children of an epic appear in `bd
ready` immediately.
If task B cannot start until task A finishes, you MUST add a `blocks` dep even
if they share the same parent epic.

```text
✅ CORRECT: Tasks in same epic with sequential dependency
   bd dep add <epic> <task-A> --type parent-child
   bd dep add <epic> <task-B> --type parent-child
   bd dep add <task-B> <task-A> --type blocks    ← B needs A first
```

```text
✅ CORRECT: Decision found during auth work that also blocks auth
   bd dep add <decision> <auth-task> --type discovered-from
   bd dep add <auth-task> <decision> --type blocks
```

### Critical: Dependency Direction

Dependencies express **requirements**, not temporal order.

```text
❌ WRONG thinking: "Phase 1 comes before Phase 2"
   bd dep add phase1 phase2

✅ RIGHT thinking: "Phase 2 NEEDS Phase 1"
   bd dep add phase2 phase1
```

The issue that has the dependency is the one that's blocked.
`bd dep add <blocked-issue> <blocker-issue>`

**Verify with `bd blocked`** -- if the wrong issue shows as blocked, the
direction is inverted.

### When NOT to Use `blocks`

`blocks` is the only type that affects `bd ready`.
Overusing it creates artificial bottlenecks.
The test:
**"Can the primary deliverable of B be completed and verified without A?"**

- No, impossible to complete or verify → `blocks`
- Yes, partially or with placeholders → `related`

- ❌ "Docs should cover auth" → use `related` (docs can start:
  structure, getting-started, non-auth sections)
- ❌ "I found this bug while working on auth" → use `discovered-from`
- ❌ "These are both part of the same epic" → use `parent-child`
- ✅ "Auth endpoint needs database tables that don't exist yet" → `blocks` (can't
  run, test, or verify without the DB)

**Litmus test:** "Can I complete and verify B, or only start it?" Starting is
not enough -- if you can't ship B without A, it's `blocks`.

## Pattern: Decision Gates

When an architectural question blocks multiple implementation tasks, model it
explicitly:

1. Create a `decision` type issue at appropriate priority
2. Add `blocks` deps from every task that depends on the answer
3. Resolve the decision (capture rationale in description or notes)
4. Close the decision issue
5. `bd ready` automatically surfaces the unblocked work

```bash
bd create "Decision: CEL rule composition -- OR vs AND" -t decision -p 0
bd dep add <task-needing-answer-1> <decision-id>
bd dep add <task-needing-answer-2> <decision-id>
bd dep add <task-needing-answer-3> <decision-id>
# ... resolve, document, close
bd close <decision-id> --reason "Rules are OR'd -- documented in notes"
```

**When to use:** Any time you catch yourself thinking "I can't do X until we
decide Y" and X involves more than one task.

**Capture to Basic Memory:** When closing a decision gate, also write a note to
`artifacts/architecture/` with the full reasoning.
The beads issue tracks *what* and *when*; Basic Memory tracks *why*.

## Pattern: Discovered-From Links

When working on issue A and you find new work needed:

```bash
bd create "Found: passthrough violates spec §9.2.1" -t bug -p 2 \
  --deps discovered-from:<parent-id>
```

**Why this matters:**

- Creates a provenance graph -- trace why any issue exists
- Does NOT block anything (unlike `blocks`)
- Enables queries like "what did we discover during auth work?"
- Prevents orphaned issues with no context

**Discipline:** Every issue created during implementation of another issue
should have a `discovered-from` link.
No exceptions.

## Pattern: Sub-Agent Dispatch via Ready Queue

When dispatching parallel sub-agents:

1. Query ready work:
   `bd ready --json --limit 5`
2. Filter for independence (no shared files or concerns)
3. Each sub-agent claims atomically:
   `bd update <id> --claim`
4. Sub-agents work, discover new issues with `discovered-from` links
5. Sub-agents close completed work
6. Orchestrator re-queries `bd ready` -- new work may have unblocked

**Label routing for specialization:**

```bash
bd ready --labels documentation  # doc-writing agent
bd ready --labels implementation # code agent
bd ready --labels testing        # test agent
```

**Anti-pattern:** Don't dispatch agents to blocked issues.
Always use `bd ready`, never `bd list --status open`.

## Pattern: Basic Memory ↔ Beads Integration

Maintain bidirectional links between beads issues and Basic Memory notes:

**Beads → Basic Memory:** When closing a decision or completing significant
work, write a Basic Memory note and set `external_ref`:

```bash
bd update ISSUE_ID --external-ref "bm://artifacts/architecture/decision-name"
```

**Basic Memory → Beads:** In Basic Memory notes, reference beads issue IDs in
observations:

```markdown
- [decision] CEL rules use OR composition (bjam-ck8) #architecture
```

## Pattern: Phase Transitions and Compaction

When a project phase completes (e.g., V1 ships, sprint ends):

1. Verify all phase issues are closed
2. Create the next phase epic, bond it to the completed phase if sequential
3. After 30+ days, compact old closed issues to save context:

   ```bash
   bd admin compact --days 30
   ```

**When to compact:** Only after a clean phase boundary.
Never compact issues that might need re-reading for active work.

## Session Rituals

### Session Start

1. `bd stats` -- orient:
   how many open, blocked, ready?
2. `bd ready` -- see what's unblocked
3. Check for stale `in_progress` issues -- close if done, they may be blocking
4. Review blocked issues -- are blockers actually resolved but not closed?

### Session End

1. Close completed work with meaningful `--reason`
2. Create `discovered-from` issues for anything found but not addressed
3. Update `in_progress` issues with notes on current state
4. Push (if authorized)

## Anti-Patterns

| Anti-Pattern | Why It's Wrong | Do Instead |
|-------------|----------------|------------|
| Using `blocks` for soft relationships | Artificially constrains `bd ready` | Use `related` or `discovered-from` |
| Using only `parent-child` for sequential tasks | Children appear in `bd ready` immediately -- no blocking | Add `blocks` deps between tasks that have ordering constraints |
| Creating issues without deps | Orphaned issues with no context | Always link to parent or discovery source |
| Leaving `in_progress` issues stale | Blocks downstream work silently | Close or update with notes |
| Ignoring `bd ready` and picking manually | Defeats dependency tracking | Trust the graph |
| Skipping `discovered-from` links | Loses provenance | Link every discovered issue |
| Creating issues without descriptions | Next agent has no context | Always include `--description` |

## Rationalization Table

Excuses agents make and why they're wrong:

| Excuse | Reality |
|--------|---------|
| "`blocks` is stronger than `discovered-from`" | They're orthogonal. Use both when an issue is discovered AND blocking. |
| "`parent-child` implies blocking" | It does NOT. `parent-child` is organizational only. Add explicit `blocks` for sequencing. |
| "I'll add the deps later" | You won't. Add deps at creation time. |
| "This is too simple for a decision issue" | If 2+ tasks depend on the answer, it's a decision gate. Model it. |
| "I know what to work on without `bd ready`" | The graph knows better. Trust it. |
| "The description is obvious from the title" | Titles are for scanning. Descriptions are for the next agent. |
| "Everything blocks docs" | Docs can always start partially. Use `related` unless impossible. |
