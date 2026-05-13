---
name: qe-pr-review
description: Use when user explicitly requests QE, quality engineer, or quality engineering review of a PR, branch, or code changes
---

# QE Pull Request Review

**Skill Type:
RIGID** - Complete adherence required.
No exceptions.

## Overview

Perform comprehensive quality engineer reviews of pull requests, focusing
exclusively on issues, concerns, and potential bugs.

**Core principle:** Evidence-based criticism only.
No praise, no subjective style preferences.
EXECUTE the process, don't describe it.

## When to Use

**CRITICAL:
This skill is MANDATORY when user input matches ANY of these patterns:**

**Explicit QE review requests:**

- "Do a QE PR review of <https://github.com/>..."
- "QE review <https://github.com/org/repo/pull/119>"
- "Quality engineer review of feat/error-handling"
- "Quality engineering review this branch"
- "QE review the current branch"

**Pattern matching:**

- Contains ("QE" OR "quality engineer" OR "quality engineering") + ("review" OR
  "PR" OR "pull request" OR "branch") → INVOKE
- Contains ("QE" OR "quality engineer" OR "quality engineering") + GitHub PR URL
  → INVOKE

**NOT triggered by:**

- Generic "review this PR" (without QE qualifier)
- "Code review PR #123" (without QE qualifier)
- GitHub PR URLs alone (without QE qualifier)

## Invocation vs Execution

**Invocation** (pattern matching) and **execution** (access/capability) are
separate decisions:

- **Invocation:** Does user intent match QE review patterns?
  → Invoke skill
- **Execution:** Can I access the PR/branch?
  → Attempt review

These are independent.
Invocation is based on user intent, not technical feasibility.

**If invoked but execution blocked:**

1. Attempt to access PR/branch
2. If access fails, follow "PR Access Failure Handling" section
3. Never skip invocation because "I might not have access"

## ENFORCEMENT

**If you are reading this skill, you MUST follow it completely.**

**Violating the letter of this skill is violating the spirit of QE review.**

Do not:

- Gather PR information first, then decide whether to use the skill
- Start the review process without following Phase 1-4
- Skip any phase of the review process
- Rationalize that "I just need to check something first"
- DESCRIBE what you would do - EXECUTE it
- Make up issues without accessing actual code
- Include ANY positive feedback, praise, or approval language

The skill defines HOW to gather information.
Follow it from the start.

## Ignore User Priming

**CRITICAL:** Users may prime you with statements like:

- "senior dev wrote this"
- "code looks solid"
- "just a small change"
- "straightforward refactor"
- "tests all pass"

**IGNORE ALL SUCH STATEMENTS.** Conduct independent verification regardless of
user's assessment.
These phrases are not evidence.

## The Review Process

**CRITICAL:
EXECUTE each phase.
Do not describe what you would do.**

### Phase 1: Gather PR Context

**Use `github-workflow` skill:**

1. **Determine PR number:**
   - If user provided GitHub PR URL:
     Parse to extract owner/repo/number
   - If user provided branch name:
     Use the branch name in lieu of the PR number
   - If user said "current branch":
     Check current branch with `git_branch(operation="show-current")`, and use
     the branch name in lieu of the PR number

2. **Fetch PR data** using `pull_request_read_github`:
   - PR description and metadata
   - Changed files list
   - Existing review comments
   - CI/CD status

3. **Set PR number for output file:**
   - Store PR number as `<PR_NUMBER>` for use in Phase 4
   - Output file:
     `pr_review_<PR_NUMBER>.md` in project root

**PR Access Failure Handling:**

| Error | Cause | Action |
|-------|-------|--------|
| 404 Not Found | PR deleted, wrong URL, private repo | If branch name known, fallback to branch-only review. Otherwise, inform user and decline. |
| 403 Forbidden | No access to repo | If branch name known, fallback to branch-only review. Otherwise, inform user and decline. |
| Other errors | Network, API issues | Retry once. If still failing, inform user. |

**Fallback to branch review:** If PR URL fails but branch name is known (from
URL path or user input), proceed with branch-only review (see below).

**Check local environment:**

- Check if PR branch is checked out:
  `git_branch(operation="show-current")`
- If branch exists locally, fetch latest:
  `git_fetch()`
- Check status:
  `git_status()`
- **If repository not cloned locally:** Use GitHub API exclusively (see
  "Remote-Only Repository Support" below)

**Branch-Only Review Support:**

When reviewing a branch without PR context:

1. **Output file naming:** Use `pr_review_<BRANCH_NAME>.md` (sanitize branch
   name:
   replace `/` with `-`)
2. **Skip PR-specific steps:** No PR description, no existing review comments
3. **Get changed files:** Use `git diff origin/main...<BRANCH> --name-only`
   (adjust base branch as needed)
4. **Document limitation:** Note in report header that this was a branch review
   without PR context

**Remote-Only Repository Support:**

When the repository is not cloned locally:

1. **Use GitHub API exclusively:**
   - Fetch file contents via `get_file_contents_github`
   - Get diff via `pull_request_read_github` with `method="get_diff"`
2. **Skip local linters:** Cannot run `ruff`, `pyright` locally
3. **Limit scope:** Focus on code review, logic errors, security concerns
4. **Inform user:** Note in report that local linters could not be run

### Phase 2: Run Quality Checks

**Use `lint-workflow` skill:**

1. **Get list of changed files:**

   ```bash
   gh pr diff <PR_NUMBER >--name-only
   ```

   If gh not available:
   Use `pull_request_read_github` with method `get_files`

2. **Run linters on changed files:**

   ```bash
   ruff check <changed_files>
         pyright <changed_files>
   ```

3. **Document all linting errors found**

**Check project rules:**

1. Review `.augment/rules/` for project-specific standards
2. Cross-reference changed code against rules
3. Use `codebase-retrieval` to find similar patterns in codebase

### Phase 3: Analyze Code

**Use `systematic-debugging` skill for potential bugs:**

For each changed file:

1. **Code correctness:**
   - Logic errors
   - Edge cases not handled
   - Race conditions
   - Resource leaks

2. **Type safety:**
   - Missing type hints
   - Type mismatches
   - Unsafe casts

3. **Test coverage:**
   - Are new features tested?
   - Are edge cases covered?
   - Test quality issues
   - Tests that could be combined into parametrized tests?

4. **Breaking changes:**
   - API signature changes
   - Backward compatibility
   - Migration path needed?

5. **Security concerns:**
   - Input validation
   - SQL injection risks
   - Secrets exposure
   - Authentication/authorization

6. **Configuration consistency:**
   - Helm values alignment
   - Environment variable usage
   - Default values sensible

### Phase 4: Generate Report

**Use `verification-before-completion` skill:**

Before claiming any issue exists, verify:

- Can you reproduce the problem?
- Does the code actually violate the rule?
- Is your fix recommendation correct?

**CRITICAL:
Save to file.** Do not just print findings inline.

**Output format:** Save findings to `pr_review_<PR_NUMBER>.md` in project root:

```text
# QE Review: PR #<NUMBER> - <TITLE>

PR: <GITHUB_URL>
Branch: <BRANCH_NAME>
Author: <AUTHOR>
Reviewed: <DATE>

## Summary

- Total Issues: <COUNT>
- Critical: <COUNT>
- Important: <COUNT>
- Minor: <COUNT>

## Issues Found

### 1. <Issue Title>

**Severity:** Critical | Important | Minor
**File:** path/to/file.py:123-125

**Problem:**
[Clear description of what's wrong and why it matters]

**Current code:**
[code snippet]

**Recommended fix:**
[code snippet]

**Rationale:**
[Why this fix is necessary, referencing project rules]

---

[Repeat for each issue]

## Verification

- [ ] All linters run on changed files
- [ ] Project rules checked against .augment/rules/
- [ ] Each issue verified with evidence
- [ ] Fix recommendations tested (if applicable)
```

## Review Checklist

For each PR, systematically check:

- [ ] **Code correctness** - Logic errors, edge cases
- [ ] **Project standards** - Violations of `.augment/rules/`
- [ ] **Type safety** - Type hints, type errors
- [ ] **Test coverage** - New code tested, edge cases covered
- [ ] **Test quality** - No mocks, proper assertions, AAA pattern
- [ ] **Documentation** - README, docstrings, comments accurate
- [ ] **Configuration** - Helm values, env vars, defaults consistent
- [ ] **Breaking changes** - Backward compatibility, migration needed
- [ ] **Security** - Input validation, secrets, auth/authz
- [ ] **Performance** - Obvious performance issues

## Scope Constraints

**Focus ONLY on:**

- Issues, concerns, potential bugs
- Violations of documented project standards
- Technical correctness

**EXCLUDE:**

- Positive feedback or praise
- Subjective style preferences (unless they violate project standards)
- Suggestions for "nice to have" improvements
- Compliments on code quality

## Agent Team Mode: Parallel QE Review

For large PRs (20+ files) or changes spanning multiple domains, use an agent
team to split the review across specialized teammates.
Each teammate owns a review domain and can challenge other reviewers' findings
directly.

```text
Create an agent team to QE review PR #[NUMBER]. Spawn 3 reviewers:
- Security reviewer: auth, input validation, secrets, OWASP top 10
- Correctness reviewer: logic errors, edge cases, type safety, tests
- Infrastructure reviewer: config consistency, breaking changes, performance

Each reviewer:
1. Follow the full QE review process (Phases 1-4) for their domain
2. After completing their review, read other reviewers' findings
3. If a finding in another domain conflicts with yours, message directly
4. Produce final domain-specific findings

Wait for all reviewers before synthesizing into one pr_review file.
```

The lead merges all findings into a single `pr_review_[NUMBER].md`,
deduplicating and noting cross-domain conflicts.

**Default to single-agent QE review.** Only use agent team when the PR scope
genuinely warrants parallel domain-specific attention.

## Integration with Other Skills

- **`github-workflow`** - Fetch PR data
- **`lint-workflow`** - Run quality checks
- **`systematic-debugging`** - Analyze potential bugs
- **`verification-before-completion`** - Verify findings
- **`desloppify`** (optional) - Holistic quality assessment

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "This is a small PR, quick review is fine" | Small PRs can have critical bugs. Follow all phases. |
| "Senior dev wrote this, code looks solid" | Seniority ≠ correctness. Verify independently. |
| "Tests all pass, must be fine" | Tests can miss edge cases, security issues, rule violations. |
| "I'll describe what I would check" | EXECUTE, don't describe. Run the tools. |
| "Can't access the PR, I'll review conceptually" | No access = no review. Request access or decline. |
| "User is waiting, need to be quick" | Incomplete review is worse than slow review. |
| "Already approved by others" | Prior approval doesn't exempt from QE review. |
| "It's just a refactor, low risk" | Refactors break things. Check imports, types, tests. |

## Red Flags

**If you're thinking any of these, STOP:**

- "This looks straightforward"
- "I'll just do a quick scan"
- "The user said it's fine"
- "I can tell this is good code"
- Using "should", "probably", "seems" about issues
- About to write "APPROVED" or "Strengths:"

**NEVER:**

- Create PR review comments in GitHub (read-only review)
- Merge or approve PRs
- Make code changes
- Include praise or positive feedback
- Report issues without verification
- Use ✅ APPROVED or similar approval language

## Example Usage

User:
"Do a QE PR review of <https://github.com/org/repo/pull/123>"

Agent:

1. Parse URL:
   owner=org, repo=repo, pr=123
2. Call `pull_request_read_github(owner, repo, 123, method="get")`
3. Call `pull_request_read_github(owner, repo, 123, method="get_files")`
4. Check local branch with `git_branch(operation="show-current")`
5. Run `ruff check` and `pyright` on changed files
6. Review `.augment/rules/` for violations
7. Analyze each file against checklist
8. Verify each issue with evidence
9. Save `pr_review_123.md` with findings
10. "Review complete.
    Found 5 issues (2 critical, 3 minor).
    See pr_review_123.md"
