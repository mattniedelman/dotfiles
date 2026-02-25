---
name: fixing-linting-ci
description: Use when CI linting checks fail and need to be fixed locally - reproducing failures with act, fixing issues, pushing, and waiting for CI verification
---

# Fixing Linting CI Issues

## Overview

CI linting failures block PRs.
Fix them systematically by reproducing locally, fixing issues, and verifying the
fix passes in CI.

**Core principle:** Reproduce locally before fixing.
Verify in CI after pushing.

## The Iron Law

```text
LINTING FIXES MUST NOT CHANGE FUNCTIONALITY
```

Only make changes that address linting errors.
Do not:

- Refactor code beyond what the linter requires
- "Improve" code while fixing lint errors
- Change logic, even if it "looks wrong"
- Add features or fix bugs discovered during linting

**If a linting fix would change behavior, STOP and ask for approval.**

| Allowed | Requires Approval |
|---------|-------------------|
| Formatting, whitespace | Any logic change |
| Import ordering/grouping | Adding/removing code |
| Adding type hints | Changing function signatures |
| Removing unused imports | Removing "unused" code that may be used dynamically |
| Style fixes (quotes, trailing commas) | Renaming beyond what linter requires |

## The Workflow

```text
1. REPRODUCE: Run linter locally with act
2. FIX: Address all linting errors
3. PUSH: Commit and push the fixes
4. VERIFY: Wait for CI checks to pass
```

## Phase 1: Reproduce Locally

Run the linting job locally using `act`:

```bash
act -s GITHUB_TOKEN=$GITHUB_TOKEN -j lint
```

**Common job names:** `lint`, `linting`, `code-quality`, `check`, `ci`

To find the correct job name, check `.github/workflows/`:

```bash
cat .github/workflows/*.yml | grep -E "^\s+\w+:" | head -20
```

Or list jobs:

```bash
act -l
```

**act flags:**

| Flag | Purpose |
|------|---------|
| `-s GITHUB_TOKEN=$GITHUB_TOKEN` | Pass GitHub token for private repos |
| `-j <job>` | Run specific job |
| `--container-architecture linux/amd64` | Force architecture (for M1/M2 Macs) |
| `-P ubuntu-latest=catthehacker/ubuntu:act-latest` | Use larger image |

## Phase 2: Fix Issues

CI typically runs **MegaLinter**, which orchestrates multiple linters.
Fix strategy:

### Running Individual Linters with act

When debugging a specific linter failure, run only that linter to iterate faster
using `act` with `--env`:

```bash
# Run a single linter by name (e.g., PYTHON_RUFF)
act -s GITHUB_TOKEN=$GITHUB_TOKEN -j lint --env ENABLE_LINTERS=PYTHON_RUFF

# Run all linters for a language (e.g., PYTHON)
act -s GITHUB_TOKEN=$GITHUB_TOKEN -j lint --env ENABLE=PYTHON

# Multiple linters (comma-separated)
act -s GITHUB_TOKEN=$GITHUB_TOKEN -j lint --env ENABLE_LINTERS=PYTHON_RUFF,PYTHON_MYPY

# Run with auto-fix enabled
act -s GITHUB_TOKEN=$GITHUB_TOKEN -j lint --env ENABLE_LINTERS=PYTHON_RUFF --env APPLY_FIXES=all
```

**Linter naming convention:** `<LANGUAGE>_<LINTER>` (e.g., `PYTHON_RUFF`,
`JAVASCRIPT_ESLINT`, `DOCKERFILE_HADOLINT`)

| Variable | Purpose |
|----------|---------|
| `ENABLE` | Enable all linters for specified languages (e.g., `PYTHON,BASH`) |
| `ENABLE_LINTERS` | Enable only specific linters by name |
| `DISABLE` | Disable all linters for specified languages |
| `DISABLE_LINTERS` | Disable specific linters |
| `APPLY_FIXES` | Auto-fix (`all`, `none`, or specific linter names) |

**Common linter names:**

| Language | Linters |
|----------|---------|
| Python | `PYTHON_RUFF`, `PYTHON_MYPY`, `PYTHON_PYLINT`, `PYTHON_BLACK`, `PYTHON_PYRIGHT` |
| JavaScript | `JAVASCRIPT_ESLINT`, `JAVASCRIPT_PRETTIER`, `JAVASCRIPT_STANDARD` |
| TypeScript | `TYPESCRIPT_ES`, `TYPESCRIPT_PRETTIER` |
| YAML | `YAML_YAMLLINT`, `YAML_PRETTIER` |
| Markdown | `MARKDOWN_MARKDOWNLINT` |
| Shell | `BASH_SHELLCHECK`, `BASH_SHFMT` |
| Dockerfile | `DOCKERFILE_HADOLINT` |
| Kubernetes | `KUBERNETES_KUBECONFORM`, `KUBERNETES_HELM` |
| Terraform | `TERRAFORM_TFLINT`, `TERRAFORM_TERRASCAN`, `TERRAFORM_FMT` |
| JSON | `JSON_JSONLINT`, `JSON_PRETTIER` |

### Step 1: Check Project Configuration

Before running any auto-fix tools, check what's configured in the project:

- `pyproject.toml` - Python tools (ruff, black, isort)
- `package.json` - Node tools (eslint, prettier)
- `.mega-linter.yml` - MegaLinter configuration
- Tool-specific config files (`.eslintrc`, `.prettierrc`, etc.)

**Only use tools already configured in the project.** Do not install new tools.

### Step 2: Try Auto-Fix First

Many linters have auto-fix capabilities.
Common tools:

| Tool | Fix Command | Notes |
|------|-------------|-------|
| ruff | `ruff check --fix .` | Python - fixes most issues |
| ruff format | `ruff format .` | Python formatting |
| eslint | `npx eslint --fix .` | JavaScript/TypeScript |
| prettier | `npx prettier --write .` | Multi-language formatting |
| black | `black .` | Python formatting |
| isort | `isort .` | Python import sorting |
| shfmt | `shfmt -w .` | Shell script formatting |
| yamllint | (no auto-fix) | Manual fixes required |
| hadolint | (no auto-fix) | Dockerfile - manual fixes |
| markdownlint | `npx markdownlint --fix .` | Markdown formatting |

### Step 3: Review Auto-Fix Changes

**Always review diffs after auto-fix before proceeding:**

```bash
git diff
```

Verify auto-fix only made expected changes.
If auto-fix changed something unexpected, revert and fix manually.

### Step 4: Manual Fixes for Remaining Issues

Not all linters support auto-fix.
For remaining errors:

1. Read the error message carefully - it usually explains the fix
2. Make the minimal change to satisfy the linter
3. Remember:
   no functionality changes without approval

**False positives / suppressions:**

If a linter error appears to be a false positive:

1. **Do not add suppressions without asking the user**
2. Explain the error and why you believe it's a false positive
3. Ask user whether to suppress or fix differently

### Step 5: Re-run and Iterate

After fixing, re-run act to verify:

```bash
act -s GITHUB_TOKEN=$GITHUB_TOKEN -j lint
```

**Keep iterating until local lint passes.**

## Phase 3: Push Changes

Follow **superpowers:git-workflow** for staging, committing, and pushing.

**Key points:**

- Review diffs before staging to ensure no unintended changes
- Get explicit user permission before committing
- Use conventional commit message:
  `fix:
  resolve linting errors`

## Phase 4: Verify in CI

Wait for CI checks to complete using the GitHub CLI:

```bash
gh pr checks --watch
```

This watches the PR checks and exits when complete.

**Alternative commands:**

| Command | Purpose |
|---------|---------|
| `gh pr checks` | Show current check status (snapshot) |
| `gh pr checks --watch` | Watch and wait for completion |
| `gh pr checks --required` | Show only required checks |
| `gh pr view --json statusCheckRollup` | JSON output for scripting |

## Quick Reference

| Phase | Command | Success Criteria |
|-------|---------|------------------|
| Reproduce | `act -s GITHUB_TOKEN=$GITHUB_TOKEN -j lint` | See same errors as CI |
| Fix | Tool-specific auto-fix commands | Local lint passes |
| Push | `git commit && git push` | Changes pushed |
| Verify | `gh pr checks --watch` | All checks pass |

## Troubleshooting

**act fails to run:**

- Ensure Docker is running
- Try `--container-architecture linux/amd64` on Apple Silicon
- Use larger image:
  `-P ubuntu-latest=catthehacker/ubuntu:act-latest`

**Local passes but CI fails:**

- Check for environment differences (Node/Python version)
- Verify all files are committed
- Check for cached dependencies in CI

**gh pr checks not working:**

- Ensure you're on a branch with an open PR
- Run `gh auth status` to verify authentication
- Use `gh pr checks <PR-number>` to specify PR explicitly

## Red Flags - STOP

If you catch yourself thinking:

- "I'll just fix this bug while I'm here"
- "This code is wrong, let me correct it"
- "This would be cleaner if I refactored it"
- "The linter is wrong, I'll suppress it"
- "This unused import might be needed, but I'll remove it anyway"
- "I know what this code should do"

**STOP.
These are functionality changes.
Ask user first.**

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "It's obviously broken" | Not your scope. Report it, don't fix it. |
| "The fix is trivial" | Trivial fixes can have non-trivial side effects. |
| "No one will notice" | CI changes are reviewed. Surprises erode trust. |
| "The linter is wrong" | Ask user before suppressing. |
| "I'm improving the code" | Improvements require approval. |

## Related Skills

- **superpowers:verification-before-completion** - Verify fixes before claiming
  success
- **superpowers:systematic-debugging** - For complex linting issues
- **superpowers:git-workflow** - Commit message conventions
