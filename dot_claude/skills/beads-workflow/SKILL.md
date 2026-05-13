---
name: beads-workflow
description: Use when running any `br` (or legacy `bd`) command or working in a project with beads_rust issue tracking. Covers `br` vs `bd` differences, dependency direction, sync/JSONL model, priority syntax, and when to escalate vs create an issue.
---

# Beads Workflow Patterns (br / beads_rust)

Judgment calls for beads_rust issue tracking that agents get wrong without
guidance.
This skill covers *how to think about* beads, not exhaustive CLI reference --
run `br --help` or `br robot-docs guide` for that.

## bd vs br

`bd` is aliased to `br` in this user's fish config.
The Rust rewrite (br) drops features the Go `bd` had:

| Dropped command | Replacement |
|-----------------|-------------|
| `bd dolt push / pull / status` | `git add .beads/issues.jsonl && git commit && git push` -- JSONL is the sync boundary |
| `bd prime` | `br stats` plus `br ready` at session start |
| `bd remember` / `bd memories` | Basic Memory (`mcp__basic-memory__*`) for cross-session knowledge |
| `bd edit` (opened $EDITOR) | `br update <id> --title/--description/--notes` -- never blocks |

If you catch yourself running any of the dropped commands, stop and use the
replacement.
They will error; it is intentional.

## Priority Syntax

`br` priority is numeric (0-4) or P-form (P0-P4).
Do NOT use word values (`high`, `medium`, `low`) -- they are rejected.

| Value | Meaning |
|-------|---------|
| 0 / P0 | Critical |
| 1 / P1 | High |
| 2 / P2 | Medium (default) |
| 3 / P3 | Low |
| 4 / P4 | Backlog |

## Dependency Direction

`br dep add <child> <parent>` means **child depends on parent**.
The child is blocked until the parent closes.

```bash
# "implement X depends on design-X" -- design must close first
br dep add br-impl-x br-design-x
```

Read as:
argument 1 is blocked by argument 2.

## Sync Model

- SQLite is the live store; `.beads/issues.jsonl` is the git-tracked export.
- Mutating commands auto-flush JSONL by default.
  You usually do not need to run `br sync --flush-only`.
- To share state:
  commit `.beads/issues.jsonl` like any other source file.
- To adopt state from a pull:
  `br sync --import-only` (not automatic).
- Never commit `.beads/beads.db` -- it is local-only.

## When to File an Issue vs. Just Do It

| Situation | File an issue? |
|-----------|----------------|
| One-line typo fix | No |
| Discovered while doing other work, 5+ min of work | Yes -- create as `discovered` and link to current work |
| Pattern you want to revisit later | Yes -- issue with `--defer --until <date>` |
| A bug affecting current session only | No -- fix inline or surface to user |
| Anything the V-model routes through `/start` | The change set handles tracking; a duplicate bd/br issue is noise |

## Claiming Work

```bash
br update <id> --status in_progress --assignee "$USER"
```

There is no `--claim` shortcut in `br`.
If you see `--claim` in old docs, that was the `bd` flag.

## Closing Work

```bash
br close <id> --reason "Shipped in PR #123"
br close <id1> <id2> <id3>    # batch close
```

Close with a reason when the outcome is non-obvious.
"Done" is fine for routine tasks.

## Discovered-From Links

When a finding surfaces while working on a different issue, link them:

```bash
br create "Found: <thing>" --type bug --priority 2
br dep add <new-id> <current-work-id> --type related
```

Use `related` (not `blocks`) for discovered-from -- the new work is not blocking
the current work; it just came from it.

## Common Mistakes

| Mistake | Correct approach |
|---------|------------------|
| Using TodoWrite for project tasks | `br create` -- todos die with the session, beads persist |
| `br init` when `.beads/` already exists | Stop. Run `br status`; the workspace is already there |
| Committing `.beads/beads.db` | `.gitignore` it. Only `issues.jsonl` belongs in git |
| Word priorities (`--priority=high`) | Numeric: `--priority=1` |
| `bd dolt push` to "sync" | No dolt. `git add .beads/issues.jsonl && git commit && git push` |

## Escalation to Human

Escalate (surface to user, do not self-resolve) when:

- `br doctor` reports data inconsistencies (do NOT run `--repair` without
  asking)
- A migration, rename, or bulk operation would touch more than ~20 issues
- Deleting issues (`br delete`) -- tombstones propagate through JSONL
- You are about to run `br sync --import-only --force` or `--rebuild`
