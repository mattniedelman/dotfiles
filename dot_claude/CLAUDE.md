# Project Instructions for AI Agents

This file provides instructions and context for AI coding agents working on this
project.

## Project Context

This repo primarily uses Python, YAML, Markdown, and Shell.
When working with chezmoi-managed dotfiles, always check for template syntax and
chezmoi-specific conventions before editing.

## Sandbox & Authentication

When debugging sandbox/authentication issues (gh CLI, 1Password, AWS
credentials), check whether the tool works outside the sandbox first.
If it does, the issue is sandbox isolation -- focus on
allowRead/allowWrite/sandbox exclusion config rather than re-authenticating or
diagnosing the tool itself.

## Terminology

When the user says "my notes", "my note", or refers to notes without further
qualification, they mean their Basic Memory notes stored in `~/basic-memory`.
Use the Basic Memory MCP tools (`mcp__basic-memory__*`) to search, read, or
write them -- do not create plain files under `~/basic-memory` directly.

## Skills

Before responding to ANY user message, check if a skill might apply.
If there is even a 1% chance a skill applies, invoke it with the Skill tool
BEFORE doing anything else -- including clarifying questions, exploring code, or
gathering context.

Skill priority:
process skills first (brainstorming, debugging), then implementation skills.

## General Rules

When asked to walk through or demonstrate a workflow, explain it step-by-step
with commentary -- do NOT start autonomously running commands to explore the
codebase unless explicitly asked to.

When a simple, direct solution exists, prefer it over clever wrapper scripts or
multi-layer abstractions.
If the user rejects an approach, do not propose increasingly complex
alternatives -- step back and ask what direction they prefer.

Do not expand scope beyond what was asked.
If asked to fix broken symlinks at the top level, fix the top level -- do not
audit subdirectories and report additional findings unless explicitly asked.

When debugging, check the source code for the obvious one-line fix before
launching a multi-step investigation.
If the debugging loop hits 3 attempts with no root cause, stop and state clearly
what you know and what you don't -- do not keep probing.

When a process or script dies unexpectedly, resist adding process-management
infrastructure (nohup, setsid, PID files, resumability) as the first response.
Instead, ask whether the architecture is right before layering on
process-management complexity.

Do not call lifecycle commands (start, stop, init, restart) on services that
manage themselves automatically.
Check whether the service auto-starts before issuing manual start/stop calls.

## Debugging

After applying a config or service change, always verify the running process has
been restarted/reloaded to pick up the change.
Do not declare a fix complete until the fix is confirmed in the running system.

When reading log files for analysis, always read the FULL file (or at minimum
tail/grep for relevant entries) -- never just read the head of a log file and
assume that's representative.

When presenting multiple options for a fix, do not order them by your preferred
complexity -- put the simplest working option first.
If the user picks an option you listed last, treat that as a signal your
ordering was wrong.

<!-- BEGIN BEADS INTEGRATION v:2 profile:br -->
## Beads Issue Tracker (br)

This project uses **br (beads_rust)** for issue tracking.
`bd` is aliased to `br` so existing muscle memory works; subcommands that
existed only in the old Go `bd` (`dolt`, `prime`, `remember`, `memories`) were
dropped in the migration and will error loudly.

Storage is SQLite plus a git-tracked `.beads/issues.jsonl` export.
No Dolt backend, no automatic commits, no background daemon.

### Quick Reference

```bash
br ready              # Find available work
br show <id>          # View issue details
br update <id> --status in_progress --assignee "$USER"  # Claim work
br close <id>         # Complete work
br stats              # Project stats (replaces bd prime at session start)
```

### Rules

- Use `br` for ALL task tracking -- do NOT use TodoWrite, TaskCreate, or
  markdown TODO lists
- Persistent cross-session knowledge goes to Basic Memory
  (`mcp__basic-memory__*`), not to MEMORY.md files and not to a `bd remember`
  equivalent (`br` has none)
- JSONL auto-flushes on mutating commands; commit `.beads/issues.jsonl` like any
  other source file when you want to share state

## Session Completion

**When ending a work session**, you MUST complete ALL steps below.
Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs
   follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   git push
   git status  # MUST show "up to date with origin"
   ```
   If `.beads/issues.jsonl` changed during the session, stage and commit it with
   the rest of the work before pushing.
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->


## Build & Test

_Add your build and test commands here_

```bash
# Example:
# npm install
# npm test
```

## Architecture Overview

_Add a brief overview of your project architecture_

## Text Output

Use only ASCII punctuation in all file output:
- Dashes:
  `--` (not `—` or `–`)
- Quotes:
  `"..."` and `'...'` (not `"..."` or `'...'`)
- Ellipsis:
  `...` (not `…`)
- Spaces:
  regular spaces only (not non-breaking or narrow variants)

The `ascii_check` PostToolUse hook auto-corrects these, but writing them
correctly avoids the correction cycle.

## Conventions & Patterns

### Python package management

- NEVER run `pip`, `pip3`, `python -m pip`, or `python3 -m pip`.
  A PreToolUse hook blocks these.
- Use `uv` for everything Python:
  - `uv add <pkg>` to add a project dependency (preferred -- updates
    `pyproject.toml` + `uv.lock`)
  - `uv add --dev <pkg>` for dev dependencies
  - `uv remove <pkg>` to drop a dependency
  - `uv run <cmd>` to execute inside the project's environment
  - `uv tool install <pkg>` for standalone CLI tools
  - `uv pip install <pkg>` only as a last resort for ad-hoc virtualenvs --
    prefer `uv add`
- If a repo isn't uv-managed yet, run `uv init` before adding deps.
