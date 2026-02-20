---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - creates isolated git worktrees with smart directory selection and safety verification
---

# Using Git Worktrees

## Overview

Git worktrees create isolated workspaces sharing the same repository, allowing
work on multiple branches simultaneously without switching.

**Core principle:** Systematic directory selection + safety verification =
reliable isolation.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an
isolated workspace."

## Directory Selection Process

**CRITICAL:
Worktree directories MUST be inside the repository root, NOT siblings.**

```bash
# Get the repo root - ALL paths are relative to this
REPO_ROOT=$(git rev-parse --show-toplevel)
```

Follow this priority order:

### 1. Check Existing Directories (Inside Repo)

```bash
# Check in priority order - INSIDE the repo
ls -d "$REPO_ROOT/.worktrees" 2>/dev/null     # Preferred (hidden)
ls -d "$REPO_ROOT/worktrees" 2>/dev/null      # Alternative
```

**If found:** Use that directory.
If both exist, `.worktrees` wins.

**WRONG (sibling):** `/path/to/parent/worktrees/repo-name-branch/` **CORRECT
(inside):** `/path/to/parent/repo-name/.worktrees/branch-name/`

### 2. Check Project Config

Look for worktree directory preference in project configuration.

### 3. Ask User

If no directory exists and no preference specified:

```text
No worktree directory found. Where should I create worktrees?

1. .worktrees/ (inside repo, hidden) - RECOMMENDED
2. ~/.config/superpowers/worktrees/<project-name>/ (global location)

Which would you prefer?
```

**Note:** Option 1 creates `$REPO_ROOT/.worktrees/`, not a sibling directory.

## Safety Verification

### For Project-Local Directories (.worktrees or worktrees)

**MUST verify directory is ignored before creating worktree:**

```bash
# Check if directory is ignored (respects local, global, and system gitignore)
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**If NOT ignored:**

1. Add appropriate line to .gitignore
2. Commit the change
3. Proceed with worktree creation

**Why critical:** Prevents accidentally committing worktree contents to
repository.

### For Global Directory (~/.config/superpowers/worktrees)

No .gitignore verification needed - outside project entirely.

## Creation Steps

### 1. Detect Project Root and Name

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
project=$(basename "$REPO_ROOT")
```

### 2. Verify Target Path is Inside Repo

**CRITICAL CHECK before creating any worktree:**

```bash
# The worktree parent directory MUST start with $REPO_ROOT
worktree_parent="$REPO_ROOT/.worktrees"  # or $REPO_ROOT/worktrees

# WRONG - this would be a sibling:
# worktree_parent="$(dirname "$REPO_ROOT")/worktrees"  # DO NOT DO THIS
```

### 3. Create Worktree

```bash
# Create worktree with new branch
git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

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
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check config → Ask user |
| Directory not ignored | Add to .gitignore + commit |
| Tests fail during baseline | Report failures + ask |

## Red Flags

**Never:**

- Create worktree directory as a SIBLING to the repo (e.g., `../worktrees/`)
- Create worktree without verifying it's ignored (project-local)
- Skip baseline test verification
- Proceed with failing tests without asking
- Assume directory location when ambiguous

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
  existing > config > ask
- Verify directory is ignored for project-local
- Auto-detect and run project setup
- Verify clean test baseline

## Integration

**Called by:**

- **brainstorming** (Phase 4) - REQUIRED when design is approved and
  implementation follows
- **subagent-driven-development** - REQUIRED before executing any tasks
- **executing-plans** - REQUIRED before executing any tasks
- Any skill needing isolated workspace

**Pairs with:**

- **finishing-a-development-branch** - REQUIRED for cleanup after work complete
