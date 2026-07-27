# Project Instructions for AI Agents

It is never appropriate to run any form of `find /`

## Skills

Before responding to ANY user message, check if a skill might apply.
If there is even a 1% chance a skill applies, invoke it with the Skill tool
BEFORE doing anything else -- including clarifying questions, exploring code, or
gathering context.

Skill priority:
process skills first (brainstorming, debugging), then implementation skills.

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

Before searching the filesystem for a config file or its schema, check official
docs, `--help`, or man pages first.
When a search is still needed, scope it to the directories that tool is known to
use (XDG config dirs, project root, package install path) -- never scan the
whole filesystem broadly.

## Posting Content Attributed to Me

When an action posts content that will appear under my name -- anything a reader
would take as authored by me -- show me a draft and get my explicit approval
before posting.
This is about authorship, not just the mechanics of the action:
the permission prompt asks "may I run this command?"; this rule asks "do you
approve these words going out under your name?"

This applies to PR descriptions and review bodies, PR and issue comments,
release notes, discussion posts, gists, emails, chat/Slack messages, and any
similar externally visible, attributed content.
Draft first, wait for my go-ahead, then post -- do not combine drafting and
posting into one step.

It does NOT apply to content that is clearly machine-attributed or
non-authorial:
commit messages and trailers, code and config, internal artifacts (change files,
tracking notes), or anything where I have already reviewed the exact text in
this session.

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

<!-- BEGIN BEADS INTEGRATION v:2 profile:bd-manual -->
## Beads Issue Tracker (bd)

Projects may use **bd (beads, gastownhall/beads)** for issue tracking.
Installed via mise (`github:gastownhall/beads`); `bd` resolves on `$PATH`.
The full command surface is available -- including `dolt`, `prime`, `remember`,
and `memories` (these were absent from the interim beads_rust build and are
back).

Storage is an embedded Dolt database plus a `.beads/issues.jsonl` export.
Embedded mode runs the Dolt engine in-process -- no external server, no port, no
background daemon.
Dolt auto-commit defaults to off.

`.beads/` is NOT committed to git -- the whole directory stays gitignored.
beads is a local working store; the only task artifact that reaches git is the
rendered `tasks.md` (see rule:
beads-vmodel-tracking).

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress --assignee "$USER"  # Claim work
bd close <id>         # Complete work
bd stats              # Project stats (also: bd status, bd prime at session start)
```

### Rules

- If `bd` is initialized (check with `bd where` / `bd status`), use `bd` for ALL
  task tracking -- do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Persistent cross-session knowledge goes to Basic Memory
  (`mcp__basic-memory__*`), not to MEMORY.md files.
  bd has a `remember`/`memories` store, but Basic Memory remains the system of
  record for durable knowledge.

## Session Completion

Work is NOT complete until `git push` succeeds -- YOU must push, never stop and
wait.

1. File issues for remaining work
2. Run quality gates (if code changed) -- tests, linters, builds
3. Update issue status -- close finished work, update in-progress
4. Push:
   ```bash
   git pull && git push
   git status  # must show "up to date with origin"
   ```
   Do NOT commit `.beads/`.
   If a change set uses beads, regenerate `changes/<name>/tasks.md` before
   pushing (see rule:
   beads-vmodel-tracking).
5. Clean up stashes, prune remote branches
6. Hand off context for next session
<!-- END BEADS INTEGRATION -->


## Text Output

Use only ASCII punctuation in all file output:
- Dashes:
  `--` (not ` -- ` or `-`)
- Quotes:
  `"..."` and `'...'` (not `"..."` or `'...'`)
- Ellipsis:
  `...` (not `...`)
- Spaces:
  regular spaces only (not non-breaking or narrow variants)

The `ascii_check` PostToolUse hook auto-corrects these, but writing them
correctly avoids the correction cycle.

## Conventions & Patterns

### Git Workflow

Default workflow is simplified git flow -- not trunk-based, not
squash-and-rebase.
This overrides any skill that defaults to squash/rebase (e.g.,
`git-discipline`).

- **Branching:** `main` and `dev` are long-lived; feature branches from `dev`,
  hotfix branches from `main`.
- **Merging:** merge with `--no-ff` -- never rebase shared branches, never
  squash.
- **Commits:** Conventional Commits format; only commit when explicitly asked.
- **PRs:** create PRs to merge feature/fix branches; never merge directly to
  `main` or `develop` in conversation.
- **Conflicts:** resolve conflict by conflict -- never abort and discard.
- **Pulls:** `git pull` (no `--rebase`).


<!-- SEMBLE_START -->
## Semble Code Search

A `semble` MCP server is available with two tools:
- `mcp__semble__search` -- search the codebase with a natural-language or code
  query.
- `mcp__semble__find_related` -- find code similar to a specific file and line.

Always call `mcp__semble__search` before using Grep, Glob, or Read to explore
the codebase.
Use Grep/Glob/Read only for exact path lookup, exhaustive literal matches, or
when the returned chunk lacks enough context.

Pass `--content docs` to search documentation and prose, `--content config` for
config files, or `--content all` to search code, docs, and config together.

For CLI fallback or sub-agents without MCP access, use:

```bash
semble search "authentication flow" ./my-project
semble search "deployment guide" ./my-project --content docs
semble search "database host port" ./my-project --content config
semble find-related src/auth.py 42 ./my-project
semble search "save model to disk" ./my-project --top-k 10
```

The index is built on first run and cached automatically.
If `semble` is not on `$PATH`, use `uvx --from "semble[mcp]" semble`.

### Workflow

1. Start with `mcp__semble__search` to find relevant chunks.
2. Use `--content docs` for documentation, `--content config` for config files,
   or `--content all` for everything.
3. Inspect full files only when the returned chunk does not give enough context.
4. Optionally use `mcp__semble__find_related` with a promising result's
   `file_path` and `line` to discover related implementations.
5. Use Grep/Glob/Read only when you need exhaustive literal matches or quick
   confirmation of an exact string.
<!-- SEMBLE_END -->

@RTK.md
