# GitHub Agentic Workflows Reference

Extended reference material for gh-aw authoring.

## Bash Tool Configuration

Any command the agent uses in prompts must be allowlisted:

```yaml
tools:
  bash:
    - "find src -name '*.py' -type f"
    - "grep -rE 'pattern' src"
    - "sort"  # If prompt uses pipes with sort
    - "cat"
    - "head -n 100"
```

**Common patterns:**

| Use Case | Bash Entry |
|----------|------------|
| Find files | `find <path> -name '<pattern>' -type f` |
| Search content | `grep -rE '<pattern>' <path>` |
| Read files | `cat`, `head -n <N>`, `tail -n <N>` |
| List files | `ls -la` |
| Sort/filter | `sort`, `uniq`, `wc -l` |

## Cross-Repo Access

For workflows accessing other repositories:

```yaml
tools:
  github:
    toolsets: [issues, pull_requests, repos]
    github-token: ${{ secrets.ORG_PAT || secrets.GITHUB_TOKEN }}
```

**PAT requirements:**

| Access Type | Required Scope |
|-------------|----------------|
| Read issues/PRs | `repo` (private) or `public_repo` |
| Write issues/PRs | `repo` |
| Read code | `repo` or `contents:read` |
| Trigger workflows | `workflow` |

## Network Allowlist

```yaml
network:
  allowed:
    - defaults  # GitHub, npm, standard registries
    - api.augmentcode.com  # Augment API (required for Auggie)
    - pypi.org  # If installing Python packages
    - registry.npmjs.org  # If installing npm packages
```

## Workflow Triggers

### Schedule (Cron)

```yaml
on:
  schedule:
    - cron: "0 8 * * 1"  # Monday 8 AM UTC
```

### Workflow Run (Chain workflows)

```yaml
on:
  workflow_run:
    workflows: ["CI"]
    types: [completed]
    branches: [main]
```

**Accessing workflow_run data:**

```yaml
env:
  TRIGGERING_RUN_ID: ${{ github.event.workflow_run.id }}
  TRIGGERING_CONCLUSION: ${{ github.event.workflow_run.conclusion }}
  HEAD_SHA: ${{ github.event.workflow_run.head_sha }}
```

### Repository Dispatch (External triggers)

```yaml
on:
  repository_dispatch:
    types: [deploy, analyze]
```

## Safe Output Patterns

### Create Issue

```yaml
safe-outputs:
  create-issue:
    title-prefix: "[bot] "
    labels: [automated, needs-review]
    assignees: []  # Optional
```

### Create Pull Request

```yaml
safe-outputs:
  create-pull-request:
    title-prefix: "[auto] "
    labels: [automated]
    draft: true  # Safer default
```

### Add Comment

```yaml
safe-outputs:
  add-comment:
# No configuration needed
```

### Noop (Do nothing)

```yaml
safe-outputs:
  noop:
# Always declare if prompt can output noop
```

**Noop JSON format:**

```json
{"type": "noop", "message": "No action needed because..."}
```

## Engine Script Template

For custom Auggie engine (`scripts/auggie-engine.sh`):

```bash
#!/bin/bash
set -euo pipefail

# Read prompt from stdin
PROMPT=$(cat)

# Run auggie with the prompt
auggie chat --model "${AUGGIE_MODEL:-sonnet4.5}" --message "$PROMPT"
```

## Complete Workflow Template

```markdown
---
description: Automated analysis workflow
strict: false
timeout-minutes: 30

on:
  workflow_dispatch:
    inputs:
      target:
        description: 'Analysis target'
        required: true
  schedule:
    - cron: "0 9 * * 1"

permissions:
  contents: read
  issues: write

sandbox:
  agent: false

network:
  allowed:
    - defaults
    - api.augmentcode.com

engine:
  id: claude
  command: ./scripts/auggie-engine.sh
  env:
    AUGGIE_MODEL: sonnet4.5

safe-outputs:
  threat-detection: false
  create-issue:
    title-prefix: "[analysis] "
    labels: [automated]
  noop:

tools:
  github:
    toolsets: [issues, repos]
    github-token: ${{ secrets.ORG_PAT }}
  bash:
    - "find . -name '*.py' -type f"
    - "grep -rE 'TODO|FIXME' ."

steps:
  - name: Setup Augment Auth
    run: |
      echo '${{ secrets.AUGMENT_SESSION_AUTH }}' > /tmp/augment-session-auth.json
      echo "AUGMENT_SESSION_AUTH_FILE=/tmp/augment-session-auth.json" >> "$GITHUB_ENV"
  - name: Install Augment CLI
    run: |
      npm install -g @augmentcode/auggie
      which auggie
---

# Analysis Agent

You are an analysis agent. Your task is to analyze the repository.

## Instructions

1. Use bash tools to explore the codebase
2. Identify issues or improvements
3. Create an issue with findings OR output noop if nothing found

## Output

Use `create-issue` to report findings, or `noop` if no action needed.
```

## Debugging Failed Runs

```bash
# View run summary
gh run view <run-id>

# View all logs
gh run view <run-id> --log

# View only failed step logs
gh run view <run-id> --log-failed

# Re-run failed jobs
gh run rerun <run-id> --failed

# Watch live
gh run watch <run-id>
```

## Compilation Troubleshooting

```bash
# Compile and show warnings
gh aw compile

# Compile specific file
gh aw compile .github/workflows/my-workflow.md

# Validate without writing
gh aw compile --dry-run
```
