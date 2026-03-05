---
name: finishing-a-development-branch
description: Use when AI completes work in a worktree - walks through changes and offers to merge into user's current branch
---

# Finishing a Development Branch

## Overview

When AI completes implementation work in a worktree, walk through the changes
with the user and offer to merge into their current branch.

**Core principle:** Verify tests → Verify linting → Present summary → Offer
walk-through → Merge to user's branch.

**AI initiates this flow when work is complete** (tests pass, task fulfilled).

## The Process

### Step 1: Verify Tests

**Before presenting summary, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:** Fix them.
Don't proceed until tests pass.

### Step 2: Verify Linting (if configured)

**Check if lint workflow is configured:**

```bash
# Check for GitHub Actions lint workflow
ls .github/workflows/{lint,ci,super-linter}*.yml 2>/dev/null

# Or check for act availability and lint job
act -l 2>/dev/null | grep -i lint
```

**If lint workflow exists:**

1. Use `superpowers:lint-workflow` to verify linting passes
2. Fix any lint errors using the iteration loop from that skill
3. Don't proceed until linting passes locally AND CI confirms

**If lint workflow does NOT exist:**

Present option to user:

```text
No lint workflow detected in this project.

Would you like to:
1. Set up GitHub Actions linting (recommended for code quality)
2. Skip linting and proceed to merge
```

**If user chooses setup:**

1. Create `.github/workflows/lint.yml` using super-linter or project-appropriate
   linters
2. Run initial lint check and fix any errors
3. Commit the workflow file
4. Continue with completion

**If user chooses skip:**

Proceed to Step 3 without linting.

### Step 3: Present Summary

Present a concise summary of the work:

```text
Work complete on `feature/user-auth`.

Changes:
- Added OAuth2 provider (3 files)
- Updated user model with auth fields (1 file)
- Added tests (2 files)

6 files changed, 247 insertions, 12 deletions
Tests: 42 passed

Would you like to:
1. Walk through changes file-by-file
2. Merge into your current branch (`develop`)
3. Keep the branch for later
```

### Step 4: Handle Choice

**If walk-through requested:**

For each changed file:

1. Show the file path and change summary
2. Explain what the changes do
3. Ask "Continue to next file?" or "Questions?"

After walk-through, re-offer merge.

**If merge requested:**

1. Switch to user's main checkout
2. Identify user's current branch
3. Merge the worktree branch into it
4. Clean up worktree (Step 5)

**If keep for later:**

Report:
"Keeping branch `<name>`.
Worktree at `<path>`." Don't clean up.

### Step 5: Cleanup Worktree

After merge:

```bash
git worktree remove <worktree-path>
```

If keeping for later, don't clean up.

## Quick Reference

| Step | Action |
|------|--------|
| 1. Tests | Run project test suite, fix failures |
| 2. Lint | If configured: run lint-workflow. If not: offer setup or skip |
| 3. Summary | Present changes, stats, options |
| 4. Choice | Walk-through, merge, or keep for later |
| 5. Cleanup | Remove worktree after merge |

| Choice | Merge | Cleanup Worktree |
|--------|-------|------------------|
| Walk-through | After review | After merge |
| Merge now | Yes | Yes |
| Keep for later | No | No |

## Red Flags

**Never:**

- Proceed with failing tests
- Proceed with failing lint (if configured)
- Merge without verifying tests on result

**Always:**

- Verify tests before presenting summary
- Check for lint workflow and run if present
- Offer lint setup if not configured
- Offer walk-through option
- Clean up worktree after merge

## Integration

**Initiated by AI** when implementation work is complete (tests pass, task
fulfilled).

**Pairs with:**

- **using-git-worktrees** - Cleans up worktree created by that skill
- **lint-workflow** - Linting verification before merge
