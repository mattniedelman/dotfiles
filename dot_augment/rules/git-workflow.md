---
type: always_apply
---

# Git Workflow and Commit Conventions

## Commit Message Format

**Use Conventional Commits** for all commit messages: `<type>(<scope>): <description>`

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `refactor`: Code refactoring without changing functionality
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `build`: Build system or dependency changes
- `ci`: CI/CD configuration changes
- `chore`: Other changes that don't modify src or test files

**Examples:**
```
feat(auth): add OAuth2 authentication support
fix(api): resolve race condition in user creation
docs(readme): update installation instructions
refactor(database): simplify query builder logic
test(auth): add integration tests for login flow
```

**Commit Body (optional but recommended for complex changes):**
```
feat(api): add rate limiting middleware

Implement token bucket algorithm for API rate limiting.
Configurable limits per endpoint and per user.

Closes #123
```

**Breaking Changes:**
```
feat(api)!: change authentication response format

BREAKING CHANGE: Auth endpoint now returns JWT in 'token' field instead of 'access_token'
```

## Commit Message Confirmation Workflow

**REQUIRED PROCESS for all commits:**

1. **User requests commit** (using explicit commit language)

2. **AI analyzes changes** and generates a Conventional Commit message following the format

3. **AI presents proposed commit message** to user:
   ```
   I will commit these changes with the following message:

   feat(auth): add OAuth2 authentication support

   Implement token bucket algorithm for API rate limiting.
   Configurable limits per endpoint and per user.

   Is this commit message acceptable? (yes/no/modify)
   ```

4. **AI waits for user confirmation** before executing `git commit`

5. **If user provides their own message**, AI must:
   - Check if it follows Conventional Commits format
   - Check if it uses objective language (no subjective adjectives)
   - If non-conforming, inform user and suggest corrections
   - Ask if user wants to use the suggested correction or proceed with their version
   - Respect user's final decision even if non-conforming

**Exception**: If user provides a complete commit message in their initial request (e.g., "Commit with message: feat(api): add endpoint"), AI may skip confirmation but MUST still validate the message format and suggest corrections if needed.

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
```
feature/user-authentication
feature/oauth-integration
bugfix/login-validation
hotfix/security-patch
release/v1.2.0
```

**Naming Guidelines:**
- Use lowercase with hyphens
- Be descriptive but concise
- Include ticket/issue number if applicable: `feature/123-user-auth`

## Merge Strategy

**Prefer Merge over Rebase:**
- Use `git merge --no-ff` to preserve branch history
- Merge commits provide clear history of when features were integrated
- Easier to understand project timeline and feature development

**When to Merge:**
```bash
# Merge feature into develop
git checkout develop
git merge --no-ff feature/user-auth

# Merge develop into main for release
git checkout main
git merge --no-ff develop
```

**Merge Commit Messages:**
```
Merge branch 'feature/user-auth' into develop

Adds OAuth2 authentication support with Google and GitHub providers.
Includes comprehensive test coverage and documentation.
```

**Exception - Interactive Rebase for Cleanup:**
- Use `git rebase -i` to clean up your own feature branch before merging
- Squash "fix typo" or "wip" commits into meaningful commits
- Never rebase shared branches (develop, main)

## Pull Request Guidelines

**PR Title:** Follow conventional commit format
```
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

**Feature Development:**
1. Create feature branch from `develop`: `git checkout -b feature/new-feature develop`
2. Make commits following conventional commit format
3. Push branch and create PR to `develop`
4. Address review comments
5. Merge to `develop` with `--no-ff`
6. Delete feature branch after merge

**Hotfix Process:**
1. Create hotfix branch from `main`: `git checkout -b hotfix/critical-bug main`
2. Fix the issue and commit
3. Merge to `main` with `--no-ff`
4. Tag the release: `git tag -a v1.2.1 -m "Hotfix: critical bug"`
5. Merge to `develop` to keep it in sync
6. Delete hotfix branch

**Release Process:**
1. Create release branch from `develop`: `git checkout -b release/v1.2.0 develop`
2. Update version numbers, changelog, documentation
3. Test thoroughly
4. Merge to `main` with `--no-ff`
5. Tag the release: `git tag -a v1.2.0 -m "Release v1.2.0"`
6. Merge back to `develop`
7. Delete release branch

## Git Best Practices

**Commit Frequency:**
- Commit often with logical, atomic changes
- Each commit should represent a single logical change
- Commits should be buildable and testable

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
- Pull latest changes before starting work: `git pull origin develop`
- Communicate with team about long-running branches
- Use draft PRs for work-in-progress that needs early feedback

## Edge Cases and Special Scenarios

### Uncommitted Changes and Branch Switching
**Scenario**: User asks to switch branches but has uncommitted changes.

**AI behavior**:
1. Inform user: "You have uncommitted changes. To switch branches, you can either: (a) commit the changes, (b) stash the changes, or (c) discard the changes. Which would you prefer?"
2. Wait for explicit choice
3. Do NOT automatically commit, stash, or discard

### "Save My Work"
**Scenario**: User says "save my work" or "save these changes."

**AI behavior**:
- Interpret as: write changes to files (which is already done)
- Do NOT interpret as: commit changes
- Respond: "The changes have been saved to the files. They are not yet committed to git. Would you like to commit them?"

### Creating Pull Requests
**Scenario**: User asks to "create a PR" but changes aren't committed.

**AI behavior**:
1. Check if changes are committed
2. If not committed, inform user: "To create a PR, changes must be committed first. Would you like me to commit these changes?"
3. Wait for explicit commit authorization
4. After committing (if authorized), ask: "Would you like me to push to remote and create the PR?"
5. Require separate explicit permission for push and PR creation

### Amending Commits
**Scenario**: User asks to "fix the last commit" or "amend the commit."

**AI behavior**:
- Treat `git commit --amend` as equivalent to creating a new commit
- Require explicit permission: "Would you like me to amend the last commit?"
- Confirm the new commit message
- Warn if commit has been pushed: "This commit has been pushed to remote. Amending will require force push. Proceed?"

### Interactive Rebase
**Scenario**: User asks to "clean up commits" or "squash commits."

**AI behavior**:
- Require explicit permission for rebase operation
- Explain what will happen: "I will squash commits X, Y, Z into a single commit. This rewrites history."
- Confirm the final commit message
- Warn if commits have been pushed: "These commits have been pushed. Rebase will require force push. Proceed?"
