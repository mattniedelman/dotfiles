# omp configuration

## Workflows

When asked to walk through or demonstrate a workflow, explain it step-by-step
with commentary -- do NOT start autonomously running commands to explore the
codebase unless explicitly asked to.

## Investigation vs. action

Investigation (reading code, running diagnostics, reporting findings) and action
(editing files, applying fixes, creating plans with todos) are separate phases.
Do not cross into action during an investigation unless explicitly asked.
When asked to "look into", "check", "investigate", or "set up" something,
report what you find and stop -- do not start planning or fixing unless told to.

## Debugging

When debugging, check the source code for the obvious one-line fix before
launching a multi-step investigation.
If the debugging loop hits 3 attempts with no root cause, stop and state clearly
what you know and what you don't -- do not keep probing.

After applying a config or service change, always verify the running process has
been restarted/reloaded to pick up the change.
Do not declare a fix complete until the fix is confirmed in the running system.

When reading log files for analysis, always read the FULL file (or at minimum
tail/grep for relevant entries) -- never just read the head of a log file and
assume that's representative.

## Process management

When a process or script dies unexpectedly, resist adding process-management
infrastructure (nohup, setsid, PID files, resumability) as the first response.
Instead, ask whether the architecture is right before layering on
process-management complexity.

Do not call lifecycle commands (start, stop, init, restart) on services that
manage themselves automatically.
Check whether the service auto-starts before issuing manual start/stop calls.

## Watching for a condition

Never block on a long, fixed-iteration shell loop (`for i in $(seq 1 50); do
sleep 12; ...`). A loop like that freezes the session for many minutes with no
way for me to steer, and it keeps counting even when the thing it watches has
stalled, disappeared, or was the wrong object all along.

Instead:
- Bound every wait to something short (about a minute or two), then RETURN
  control and report current state -- do not extend the loop to chase a
  condition that hasn't happened yet.
- Re-ground each time before waiting again: re-list the resource and confirm
  you are watching the RIGHT object and that it is actually making progress
  (pod name still exists, status advancing, logs moving). A rollout can spawn a
  new pod/ReplicaSet under a different name -- the one you were watching may be
  irrelevant.
- Prefer the structured waits (`hub wait`, process `wait`) over hand-rolled
  sleep loops; they return on the first real event.
- If the condition isn't met after a bounded check, stop and say what state it
  is in and what you expected -- let me decide whether to keep waiting.

## Long-running jobs and durable output

Before launching any job that takes more than a minute (benchmarks, training,
long indexing, multi-language evals), make sure its primary result lands in a
FILE, not just stdout/stderr.
Process and daemon logs (including omp `hub` `output.log`) are bounded ring
buffers that ROTATE: a job that streams large per-item output will push its
final summary out of the retained buffer, and the result is unrecoverable once
the job ends.
If a tool offers a `--output`/`-o`/`--report` file flag, use it; if it only
prints to stdout, redirect to a file you control before launching.
Verify the output mechanism with a tiny run (small `--limit`) BEFORE committing
to the long one.

When a job's output is lost anyway, do NOT do extended log archaeology.
Spend at most a couple of minutes; if the result isn't cleanly recoverable, fix
the capture mechanism and re-run. Never burn long stretches reconstructing data
from rotated or contaminated logs.

## Presenting options

When presenting multiple options for a fix, do not order them by your preferred
complexity -- put the simplest working option first.
If the user picks an option you listed last, treat that as a signal your
ordering was wrong.

## Terminology

When the user says "my notes", "my note", or refers to notes without further
qualification, they mean their Basic Memory notes stored in ~/basic-memory.
Use the Basic Memory MCP tools (mcp__basic-memory__*) to search, read, or write
them -- do not create plain files under ~/basic-memory directly.

## Beads

Never search the filesystem for a `.beads` directory (no `find`, no glob scans).
If `bd` reports no database found, assume the user has one initialized and ask
where it is, or ask them to run `bd init` themselves.
The database is always in or above the current working directory -- `bd`
resolves it automatically when run from the right directory.


## Subagent management

Delegate to a subagent only when the work is genuinely independent and large
enough that you would not finish it inline in a handful of tool calls -- a wide
multi-file investigation, or parallel tracks with no shared state.
Judge by that criterion, not by a target count:
if one subagent can do it, use one; if the work is small or sequential, do it
yourself.
Do not spawn subagents to verify or double-check your own work.

When waiting on background subagents (`hub wait`), issue it once per stuck job.
If the timeout elapses without the job completing, call `hub cancel` on the
stuck job, note what's missing, and continue without it.
Do not re-issue `hub wait` with escalating timeouts -- that freezes the session
visibly for the user with no output.

Do not assign `web_search` work to a `librarian` agent.
The librarian tends toward network-heavy workflows that can hang indefinitely
with no way for the parent session to cancel individual tool calls.
Do web searches inline in the parent session, or use a regular `task` agent with
explicit instructions to prefer `read <url>` over `web_search`.

## Git projects

All git repositories are stored as `~/projects/$GITHUB_ORG/$GITHUB_REPO`.
When navigating to or searching for a project, scope filesystem operations to
that directory.

## Git workflow

Before making any git operation, identify the repo's branching strategy:

1. Check for `CONTRIBUTING.md` at the repo root.
2. If absent, run `git log --oneline -20` to infer the branching and commit
   style in use.
3. If still unclear, ask before proceeding.

Default to **git flow** when no strategy is evident:

- `main` is the production branch; `dev` (or `develop`) is the integration
  branch.
- Features branch from `dev` as `feature/<desc>`; hotfixes branch from `main` as
  `hotfix/<desc>`.
- Merge with `--no-ff` (preserve branch topology).
  Never squash or rebase shared branches (`main`, `dev`).
- All changes to `main` or `dev` go through a PR -- never commit directly.
- Always use Conventional Commits (`<type>(<scope>):
  <description>`).
- Never use `git add -A` or `git add .` — always stage files explicitly by
  path. Commits must be granular and intentional; bulk-adding everything in
  the working tree is forbidden.

## Python package management

Use `uv` for all Python package management.
Never use `pip`, `pip3`, or `python -m pip` directly -- they are also blocked by
a bash deny-pattern.

## hk

- Ask the hk MCP server to inspect the project and plan checks before execution.
- Scope work to changed files (`--files0-from` accepts exact NUL-delimited
  paths) and use `--cd` for another project root.
- Prefer safe checks and safe fixes.
  Inspect command effects and ask before any unknown or destructive command.
- Read normalized diagnostics from structured results, then inspect the patch
  before reporting or committing a fix.
- If MCP is unavailable, run `hk run check --format jsonl --safe`; the final
  event is the authoritative summary.


## Communication

Lead with the outcome.
Your first sentence when you finish should answer "what happened" or "what did
you find" -- the thing I'd ask for if I said "just give me the TLDR" -- with
supporting detail after it.
When you have worked a while without me watching (many tool calls, overnight),
treat the final message as a re-grounding for a reader who saw none of it:
drop the working shorthand, spell out identifiers, and write plainly.
Readability and brevity are different; when they collide, choose readable.

Match written deliverables (reports, Markdown docs, summaries written to disk)
to what the task needs -- cover the substance, do not pad with filler sections,
redundant summaries, or boilerplate.

Ground progress claims in tool results:
before reporting something as done, point to the evidence for it.
If a step is unverified or was skipped, say so plainly rather than implying
success.

Anything posted under my name -- PR descriptions and review comments, GitHub
issue and discussion comments, Slack messages, commit-adjacent prose -- must be
in my voice. Read `skill://voice-and-tone` and follow it: lowercase-first,
answer or action first, no throat-clearing, no cheerleading, no exclamation
points, no formal sign-offs. Draft in that voice from the start, not as a
cleanup pass. This does not apply to code, config, or internal artifacts.

## Model calibration

The active model is shown in the workstation block.
At session start, read `skill://model-prompting-notes` and apply the section
matching that model.
If no section matches, the guidance in this file is sufficient -- do not guess.
