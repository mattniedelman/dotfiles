---
name: using-git-worktrees
description: Use when doing AI implementation work - DEFAULT creates isolated git worktrees to keep user's main checkout pristine
---

# Using Git Worktrees

## Overview

Git worktrees create isolated workspaces sharing the same repository.
**AI defaults to worktrees for all implementation work**, keeping the user's
main checkout pristine for their own use.

**Core principle:** AI works in worktrees, user keeps main checkout.

**Announce at start:** "I'll set up a worktree for this implementation work."

## When to Use

**Default (use worktree):**

- Any task involving code changes (features, bugfixes, refactors)
- Implementation work of any size

**Skip worktree:**

- Read-only tasks (exploration, review, questions)
- User explicitly says to work in current checkout

## Canonical Path Formula

**The worktree path is ALWAYS derived from the repo root:**

```text
WORKTREE_PATH = $REPO_ROOT/.worktrees/<branch-name>
```

This is the only acceptable pattern.
There are no alternatives, no exceptions.

**Enforcement:** A `PreToolUse` hook (`worktree_placement_check.sh`) blocks any
`git worktree` add operation where the worktree path is not a descendant of the
repo root.
Sibling paths are rejected before execution.

## Directory Selection Process

**CRITICAL:
Worktree directories MUST be inside the repository root, NOT siblings.**

### 1. Check Existing Directories (Inside Repo)

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
ls -d "$REPO_ROOT/.worktrees" 2>/dev/null # Preferred (hidden)
ls -d "$REPO_ROOT/worktrees" 2>/dev/null  # Alternative
```

**If found:** Use that directory.
If both exist, `.worktrees` wins.

### 2. Default to .worktrees/ (Do Not Ask)

If no worktree directory exists, **create `$REPO_ROOT/.worktrees/`** and inform
the user.
Do not ask which directory to use -- the default is always inside the repo.

```text
Creating worktree directory at <repo>/.worktrees/
```

The `.worktrees` directory is covered by the global gitignore.

## Creation Steps

### 1. Compute the Worktree Path

Derive the path using the canonical formula.
Do not improvise.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
WORKTREE_PATH="$REPO_ROOT/.worktrees/$BRANCH_NAME"
```

### 2. Create the Worktree

**Using the git MCP tool (preferred):**

```bash
git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME"
```

**Both must produce a path inside the repo.** The `worktree_placement_check.sh`
hook will block the MCP tool call if `worktreePath` is not a descendant of
`path`.

### 3. Verify Placement

After creation, confirm the worktree is where it should be:

```bash
# The resolved worktree path MUST start with the repo root
[[ "$(realpath "$WORKTREE_PATH")" == "$(realpath "$REPO_ROOT")"/* ]]
```

If this check fails, something went wrong.
Remove the worktree and retry.

### 4. Run Project Setup

Auto-detect and run appropriate setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

### 5. Verify Clean Baseline

Run tests to ensure worktree starts clean.

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

### 6. Report Location

```text
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| `.worktrees/` exists | Use it |
| `worktrees/` exists | Use it |
| Both exist | Use `.worktrees/` |
| Neither exists | Create `.worktrees/` (do not ask) |
| Tests fail during baseline | Report failures + ask |

## Red Flags

**Never:**

- Create worktree directory as a SIBLING to the repo (e.g., `../worktrees/`)
- Skip baseline test verification
- Proceed with failing tests without asking
- Use `$(dirname "$REPO_ROOT")` or any path outside the repo
- Improvise a "reasonable" sibling path like `$REPO_ROOT-worktrees/`

**Example of WRONG placement:**

```text
/home/user/projects/
├── my-repo/                    # Main repo
└── worktrees/                  # WRONG - sibling directory
    └── my-repo-feature-branch/
```

**Example of CORRECT placement:**

```text
/home/user/projects/
└── my-repo/                    # Main repo
    └── .worktrees/             # CORRECT - inside repo
        └── feature-branch/
```

**Always:**

- Follow directory priority:
  existing `.worktrees/` > existing `worktrees/` > create `.worktrees/`
- Auto-detect and run project setup
- Verify clean test baseline
- Verify worktree path is inside repo after creation

## Integration

**This is the default first step for implementation tasks.**

AI should automatically set up a worktree when starting any code-changing task.

**Pairs with:**

- **finishing-a-development-branch** - REQUIRED for cleanup after work complete

## Commit Autonomy

In worktrees, AI can commit freely without asking permission:

- Atomic commits (one logical change per commit)
- Conventional commit format
- Commit as work progresses

See `authorization-policies.md` for details.
