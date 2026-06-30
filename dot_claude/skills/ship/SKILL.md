---
name: ship
description: Ship current work through the branch → commit → push → PR flow, stopping at review. Picks up wherever you are in the cycle. Use when the user says "ship it", "send it up", "open a PR", or invokes /ship. Merging is done manually.
allowed-tools: Bash, Read, Grep, Glob
---

# Ship Workflow

Get current work to an open, reviewable PR. Assess the current state and pick up from wherever the user is. Stop at review -- merge is the user's to do.

## Arguments

- `/ship` -- default flow, adapts review gate to repo flavor
- `/ship full-sail` -- skip the review pause (solo/pair repos only; team repos still pause)

## Assess First

Run these in parallel to determine current position in the flow:

```bash
git status --short              # Uncommitted changes?
git branch --show-current       # On main or a feature branch?
git log --oneline main..HEAD    # Commits ahead of main?
git remote show origin 2>&1     # Remote tracking state?
```

Also check repo flavor for review gating:

```bash
# Active contributors in last 90 days
git log --since="90 days ago" --format='%aN' | sort -u | wc -l
```

- **≤2 active**: Solo/pair -- lightweight PRs, review pause optional
- **3+ active**: Team -- review pause mandatory, suggest reviewers

If the GitHub way has already injected context (look for `**Context**: Team project` or
`**Context**: Solo/pair project` in the conversation), use that instead of re-checking.

## Flow Steps (skip what's already done)

### 1. Branch (if on main with changes)

```bash
git checkout -b <branch-name>
```

Pick a name from the changes: `feature/thing`, `fix/thing`, `refactor/thing`.
If the user provides a name, use it. If changes are already committed on main,
create the branch first, then it carries the commits.

### 2. Commit (if uncommitted changes)

Stage and commit. Follow conventional commit format.
If there are multiple logical changes, make multiple atomic commits.
Ask the user for a commit message direction if the intent isn't clear.

### 3. Push

```bash
git push -u origin <branch>
```

### 4. PR

```bash
gh pr create --title "..." --body "$(cat <<'EOF'
## Summary
...

## Test plan
...
EOF
)"
```

Keep the title under 70 characters. Summary should be 1-3 bullets.
For small/obvious changes, the test plan can be brief.

### 5. Review Gate (final step)

**Team repos (3+ active contributors):**
- State the change scope and suggest reviewers.
- Exception: `/ship full-sail` is rejected for team repos -- tell the user why.

**Solo/pair repos (≤2 active contributors):**
- **Default**: Offer to spawn a `pr-auditor` subagent against the PR. This is the
  normal path -- don't wait for the user to ask. Frame it as: "I'll run a code review
  on this PR" and proceed unless the user declines.
- **Trivial** (typos, config, single-file): mention the review is optional, still offer
- `/ship full-sail` skips the review

**Running the review:**

```
Agent(subagent_type="pr-auditor", prompt="Review PR #<number> in this repo.
Run gh pr diff <number> to see the changes. Post findings as a gh pr comment.")
```

After the review completes, summarize findings and hand the PR back to the user. **Stop here.** The user performs the merge, cleanup, and any publishing themselves.

## Key Principles

- **Stop at the open PR.** This skill never merges, deletes branches, or runs post-merge cleanup -- the user owns those steps.
- **Don't ask permission for each pre-PR step** -- assess state, propose the remaining flow up to review, then execute.
- **Pause only at decision points**: commit message wording, PR description, review gate.
- **If already mid-flow**, pick up from current state -- don't restart.
- **One commit is fine** for most changes; only split if there are genuinely separate concerns.
- **Repo flavor drives review**, not just change size -- a one-line fix in a team repo still pauses.
