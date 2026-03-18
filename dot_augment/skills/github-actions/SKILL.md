---
name: github-actions
description: Use when authoring, debugging, or optimizing GitHub Actions workflows - YAML syntax, triggers, security, local testing with act, monitoring with gh CLI
---

# GitHub Actions

Comprehensive reference for authoring and maintaining GitHub Actions workflows.

## When to Use

- Creating new workflow files (`.github/workflows/*.yml`)
- Debugging failing CI/CD pipelines
- Optimizing workflow performance (caching, matrix, concurrency)
- Implementing security best practices (OIDC, permissions)
- Testing workflows locally with `act`
- Monitoring workflow runs with `gh` CLI

## Workflow Structure

```yaml
name: CI  # Display name
on: [push, pull_request]  # Triggers

permissions:  # REQUIRED: explicit permissions
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "Hello"
```

## Triggers (on:)

| Trigger | Use Case | Example Filter |
|---------|----------|----------------|
| `push` | Commits to branch | `branches: [main]`, `paths: ['src/**']` |
| `pull_request` | PR events | `types: [opened, synchronize]` |
| `workflow_dispatch` | Manual trigger | `inputs: { version: { type: string } }` |
| `schedule` | Cron jobs | `cron: '0 0 * * *'` |
| `workflow_call` | Reusable workflow | Called by other workflows |
| `repository_dispatch` | External API | `types: [deploy]` |

**Path filtering:**

```yaml
on:
  push:
    paths:
      - 'src/**'
      - '!src/**/*.md'  # Exclude markdown
    branches:
      - main
      - 'release/**'
```

## Contexts and Expressions

| Context | Contains | Example |
|---------|----------|---------|
| `github` | Event data, repo, ref | `${{ github.event_name }}` |
| `env` | Environment variables | `${{ env.MY_VAR }}` |
| `secrets` | Repository secrets | `${{ secrets.API_KEY }}` |
| `inputs` | workflow_dispatch inputs | `${{ inputs.version }}` |
| `needs` | Outputs from prior jobs | `${{ needs.build.outputs.version }}` |
| `matrix` | Current matrix values | `${{ matrix.node }}` |

**Conditionals:**

```yaml
steps:
  - if: github.event_name == 'push'
    run: echo "Push event"

  - if: contains(github.event.head_commit.message, '[skip ci]')
    run: exit 0

  - if: failure()  # Run on failure
    run: echo "Something failed"

  - if: always()  # Always run
    run: echo "Cleanup"
```

## Job Dependencies and Outputs

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.version.outputs.value }}
    steps:
      - id: version
        run: echo "value=1.0.0" >> $GITHUB_OUTPUT

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying ${{ needs.build.outputs.version }}"
```

## Matrix Builds

```yaml
jobs:
  test:
    strategy:
      fail-fast: false  # Don't cancel other jobs on failure
      matrix:
        os: [ubuntu-latest, macos-latest]
        node: [18, 20, 22]
        exclude:
          - os: macos-latest
            node: 18
        include:
          - os: ubuntu-latest
            node: 22
            experimental: true
    runs-on: ${{ matrix.os }}
    continue-on-error: ${{ matrix.experimental || false }}
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
```

## Security Best Practices

**CRITICAL:
Always set explicit permissions:**

```yaml
permissions:
  contents: read  # Minimum needed
  pull-requests: write  # Only if needed

# Or restrict all jobs:
permissions: {}  # No permissions by default
```

**OIDC for cloud providers (no secrets):**

```yaml
permissions:
  id-token: write  # Required for OIDC
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::123456789:role/MyRole
      aws-region: us-east-1
```

**Script injection prevention:**

```yaml
# DANGEROUS - user input in run:
- run: echo "${{ github.event.issue.title }}"

# SAFE - use environment variable
- env:
    TITLE: ${{ github.event.issue.title }}
  run: echo "$TITLE"
```

## Caching

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: npm-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      npm-${{ runner.os }}-

# Or use setup-* action caching:
- uses: actions/setup-node@v4
  with:
    node-version: 20
    cache: 'npm'  # Built-in caching
```

## Concurrency

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true  # Cancel previous runs on same branch
```

## Local Testing with act

```bash
# Install: https://github.com/nektos/act
# Basic run (defaults to push event)
act

# Specific event
act pull_request

# Specific job
act -j build

# With secrets
act -s GITHUB_TOKEN=$GITHUB_TOKEN

# Dry run (list jobs)
act -l

# Verbose output
act -v
```

**Common act flags:**

| Flag | Purpose |
|------|---------|
| `-j <job>` | Run specific job |
| `-W <file>` | Use specific workflow file |
| `-s KEY=val` | Set secret |
| `--env KEY=val` | Set environment variable |
| `-P ubuntu-latest=catthehacker/ubuntu:act-latest` | Custom image |
| `--container-architecture linux/amd64` | Force architecture (M1 Macs) |

## Monitoring with gh CLI

```bash
# Watch workflow run (blocks until complete)
gh run watch

# Watch specific run
gh run watch <run-id>

# View run details
gh run view <run-id>

# View with logs
gh run view <run-id> --log

# View failed logs only
gh run view <run-id> --log-failed

# List recent runs
gh run list --limit 10

# Re-run failed jobs
gh run rerun <run-id> --failed

# Check PR status
gh pr checks --watch
```

## Debugging

**Enable debug logging:**

```yaml
# Set repository secret or variable:
# ACTIONS_STEP_DEBUG = true
# ACTIONS_RUNNER_DEBUG = true

# Or in workflow:
env:
  ACTIONS_STEP_DEBUG: true
```

**Step outputs for debugging:**

```yaml
- run: |
    echo "Debug info" >> $GITHUB_STEP_SUMMARY
    echo "::notice::This is a notice"
    echo "::warning::This is a warning"
    echo "::error::This is an error"
```

## Related Skills (Auto-Invoke)

After generating or modifying workflows, invoke these:

| After This Step | Invoke Skill | Why |
|-----------------|--------------|-----|
| Generate workflow | `verification-before-completion` | Test locally with `act` |
| Modify workflow | `lint-workflow` | Run `actionlint` |
| Complete changes | `knowledge-capture` | Document workflow decisions |

**Validation checklist (REQUIRED before done):**

```bash
# Lint workflows
actionlint .github/workflows/*.yml

# Test locally (requires act)
act -n  # dry-run
act push  # simulate push event

# Check syntax via gh CLI
gh workflow view <workflow-name>
```

## Error→Reference Mapping

| Error Pattern | Reference | Fix |
|---------------|-----------|-----|
| `workflow_dispatch` type error | Inputs section | Use string type for all inputs |
| `Unknown runner` | Runners table | Check valid runner labels |
| `needs: unknown-job` | Job dependencies | Verify job names match |
| `expression is not allowed` | Context availability | Check context scope |
| `Resource not accessible` | Permissions | Add required permission |
| `uses: invalid` | Action reference | Check org/repo@version format |

## See Also

See `REFERENCE.md` for:

- Reusable workflows and composite actions
- Artifact handling patterns
- Environment and deployment gates
- Complete workflow templates (CI, release, deploy)
- Action selection criteria
- Common anti-patterns
