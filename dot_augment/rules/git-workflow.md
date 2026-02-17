---
type: always_apply
priority: HIGH
description: Git workflow, conventional commits, branch naming, and version control practices
last_updated: 2026-02-13
---

# Git Workflow and Commit Conventions

## CRITICAL: Use Git MCP Server Tools

**All git operations MUST be performed through the git MCP server tools.**
Direct `git` commands via `launch-process` are blocked by tool permissions.

See `git-mcp-required.md` for the complete tool reference.

**Key MCP tools:**

- `git_status_git` - Check repository status
- `git_diff_git` - View changes
- `git_add_git` - Stage files (always stage specific files, never all)
- `git_commit_git` - Create commits
- `git_checkout_git` - Switch branches or create new branches
- `git_merge_git` - Merge branches
- `git_push_git` - Push to remote
- `git_log_git` - View commit history

## Commit Message Format

**Use Conventional Commits** for all commit messages:
`<type>(<scope>):
<description>`

**CRITICAL:
Keep commit messages concise and to the point**

- Subject line should be 50-72 characters maximum
- Use imperative mood ("add feature" not "added feature")
- No period at the end of subject line
- Body is optional - only add if truly necessary for context
- Most commits should be subject-line only

**Types:**

- `feat`:
  New feature
- `fix`:
  Bug fix
- `docs`:
  Documentation changes
- `style`:
  Code style changes (formatting, missing semicolons, etc.)
- `refactor`:
  Code refactoring without changing functionality
- `perf`:
  Performance improvements
- `test`:
  Adding or updating tests
- `build`:
  Build system or dependency changes
- `ci`:
  CI/CD configuration changes
- `chore`:
  Other changes that don't modify src or test files

**Examples (preferred - concise, no body):**

```bash
feat(auth): add OAuth2 support
fix(api): resolve user creation race condition
docs(readme): update installation steps
refactor(database): simplify query builder
test(auth): add login integration tests
```

**Body usage (only when necessary for complex changes):**

```bash
feat(api): add rate limiting middleware

Token bucket algorithm with per-endpoint and per-user limits.
Closes #123
```

**Breaking Changes:**

```bash
feat(api)!: change auth response format

BREAKING CHANGE: JWT now in 'token' field instead of 'access_token'
```

## Commit Message Confirmation Workflow

**REQUIRED PROCESS for all commits:**

1. **User requests commit** (using explicit commit language)

2. **AI analyzes changes** and generates a concise Conventional Commit message
   - Prefer subject-line only (no body)
   - Only add body if changes truly require additional context
   - Keep subject line under 72 characters

3. **AI presents proposed commit message** to user:

   ```text
   I will commit these changes with the following message:

   feat(auth): add OAuth2 support

   Is this commit message acceptable? (yes/no/modify)
   ```

4. **AI waits for user confirmation** before executing `git commit`

5. **If user provides their own message**, AI must:
   - Check if it follows Conventional Commits format
   - Check if it uses objective language (no subjective adjectives)
   - Check if subject line is concise (under 72 characters)
   - If non-conforming, inform user and suggest corrections
   - Ask if user wants to use the suggested correction or proceed with their
     version
   - Respect user's final decision even if non-conforming

**Exception**:
If user provides a complete commit message in their initial request (e.g.,
"Commit with message:
feat(api):
add endpoint"), AI may skip confirmation but MUST still validate the message
format and suggest corrections if needed.

## Branch Naming Conventions

**Use Simplified Gitflow:**

**Main Branches:**

- `main` - Production-ready code, always deployable
- `develop` - Integration branch for features, next release

**Supporting Branches:**

- `feature/<description>` - New features (branch from `develop`)
- `bugfix/<description>` - Bug fixes for `develop`
- `hotfix/<description>` - Urgent fixes for `main`
- `release/<version>` - Release preparation (branch from `develop`)

**Examples:**

```bash
feature/user-authentication
feature/oauth-integration
bugfix/login-validation
hotfix/security-patch
release/v1.2.0
```

**Naming Guidelines:**

- Use lowercase with hyphens
- Be descriptive but concise
- Include ticket/issue number if applicable:
  `feature/123-user-auth`

## Merge Strategy

**Prefer Merge over Rebase:**

- Use `git_merge_git` with `noFastForward:
  true` to preserve branch history
- Merge commits provide clear history of when features were integrated
- Easier to understand project timeline and feature development

**When to Merge (using MCP tools):**

```bash
# Merge feature into develop
git_checkout_git(target="develop")
git_merge_git(branch="feature/user-auth", noFastForward=true)

# Merge develop into main for release
git_checkout_git(target="main")
git_merge_git(branch="develop", noFastForward=true)
```

**Merge Commit Messages (keep concise):**

```bash
Merge branch 'feature/user-auth' into develop

Adds OAuth2 support with Google and GitHub providers.
```

**Exception - Interactive Rebase for Cleanup:**

- Use `git_rebase_git` to clean up your own feature branch before merging
- Squash "fix typo" or "wip" commits into meaningful commits
- Never rebase shared branches (develop, main)

## Pull Request Guidelines

**PR Title:** Follow conventional commit format

```bash
feat(auth): add OAuth2 authentication support
```

**PR Description Template:**

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Changes Made
- Bullet point list of changes
- Include technical details

## Testing
- How was this tested?
- What test cases were added?

## Related Issues
Closes #123
Relates to #456
```

**PR Best Practices:**

- Keep PRs focused and reasonably sized (< 500 lines when possible)
- Include tests for new functionality
- Update documentation as needed
- Ensure CI passes before requesting review
- Respond to review comments promptly

## Workflow Process

**Feature Development (using MCP tools):**

1. Create feature branch:
   `git_checkout_git(target="feature/new-feature", createBranch=true,
   startPoint="develop")`
2. Make commits following conventional commit format using `git_commit_git`
3. Push branch:
   `git_push_git(setUpstream=true)` and create PR to `develop`
4. Address review comments
5. Merge to `develop`:
   `git_merge_git(branch="feature/new-feature", noFastForward=true)`
6. Delete feature branch after merge

**Hotfix Process (using MCP tools):**

1. Create hotfix branch:
   `git_checkout_git(target="hotfix/critical-bug", createBranch=true,
   startPoint="main")`
2. Fix the issue and commit using `git_commit_git`
3. Merge to `main`:
   `git_merge_git(branch="hotfix/critical-bug", noFastForward=true)`
4. Tag the release:
   `git_tag_git(mode="create", tagName="v1.2.1", message="Hotfix:
   critical bug")`
5. Merge to `develop` to keep it in sync
6. Delete hotfix branch

**Release Process (using MCP tools):**

1. Create release branch:
   `git_checkout_git(target="release/v1.2.0", createBranch=true,
   startPoint="develop")`
2. Update version numbers, changelog, documentation
3. Test thoroughly
4. Merge to `main`:
   `git_merge_git(branch="release/v1.2.0", noFastForward=true)`
5. Tag the release:
   `git_tag_git(mode="create", tagName="v1.2.0", message="Release v1.2.0")`
6. Merge back to `develop`
7. Delete release branch

## Git Best Practices

**Commit Frequency:**

- Commit often with logical, atomic changes
- Each commit should represent a single logical change
- Commits should be buildable and testable

**Staging Changes - CRITICAL RULE:**

- **NEVER use `git_add_git` with `all:
  true`** - This stages all changes indiscriminately
- **ALWAYS stage specific files explicitly**:
  `git_add_git(files=["path/to/file1.py", "path/to/file2.py"])`
- **Rationale**:
  Explicit staging ensures:
  - Only intended changes are committed
  - No accidental inclusion of unrelated changes
  - No accidental commits of sensitive data, debug code, or temporary files
  - Clear understanding of what is being committed
  - Better commit hygiene and atomic commits
- **Before committing**:
  Always review exactly which files are being staged using `git_status_git`
- **Exception**:
  None.
  Always use explicit file paths.

**Commit Content:**

- Never commit secrets, API keys, or sensitive data
- Never commit large binary files (use Git LFS if needed)
- Never commit generated files (build artifacts, dependencies)
- Keep `.gitignore` up to date

**Branch Hygiene:**

- Delete branches after merging
- Keep branch names descriptive and current
- Don't let feature branches live too long (merge frequently)

**Collaboration:**

- Pull latest changes before starting work:
  `git_pull_git(remote="origin", branch="develop")`
- Communicate with team about long-running branches
- Use draft PRs for work-in-progress that needs early feedback

## Edge Cases and Special Scenarios

### Uncommitted Changes and Branch Switching

**Scenario**:
User asks to switch branches but has uncommitted changes.

**AI behavior**:

1. Inform user:
   "You have uncommitted changes.
   To switch branches, you can either:
   (a) commit the changes, (b) stash the changes, or (c) discard the changes.
   Which would you prefer?"
2. Wait for explicit choice
3. Do NOT automatically commit, stash, or discard

### "Save My Work"

**Scenario**:
User says "save my work" or "save these changes."

**AI behavior**:

- Interpret as:
  write changes to files (which is already done)
- Do NOT interpret as:
  commit changes
- Respond:
  "The changes have been saved to the files.
  They are not yet committed to git.
  Would you like to commit them?"

### Creating Pull Requests

**Scenario**:
User asks to "create a PR" but changes aren't committed.

**AI behavior**:

1. Check if changes are committed
2. If not committed, inform user:
   "To create a PR, changes must be committed first.
   Would you like me to commit these changes?"
3. Wait for explicit commit authorization
4. After committing (if authorized), ask:
   "Would you like me to push to remote and create the PR?"
5. Require separate explicit permission for push and PR creation

### Amending Commits

**Scenario**:
User asks to "fix the last commit" or "amend the commit."

**AI behavior**:

- Treat `git commit --amend` as equivalent to creating a new commit
- Require explicit permission:
  "Would you like me to amend the last commit?"
- Confirm the new commit message
- Warn if commit has been pushed:
  "This commit has been pushed to remote.
  Amending will require force push.
  Proceed?"

### Interactive Rebase

**Scenario**:
User asks to "clean up commits" or "squash commits."

**AI behavior**:

- Require explicit permission for rebase operation
- Explain what will happen:
  "I will squash commits X, Y, Z into a single commit.
  This rewrites history."
- Confirm the final commit message
- Warn if commits have been pushed:
  "These commits have been pushed.
  Rebase will require force push.
  Proceed?"
