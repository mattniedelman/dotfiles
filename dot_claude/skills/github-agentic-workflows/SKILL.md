---
name: github-agentic-workflows
description: Use when authoring GitHub Agentic Workflows (gh-aw) - markdown-based AI agent workflows, custom engines like Auggie, safe outputs, sandbox configuration, and testing from PR branches
paths: ".github/workflows/**/*.md"
---

# GitHub Agentic Workflows (gh-aw)

Reference for authoring GitHub Agentic Workflows - AI agent workflows authored
in markdown and compiled to GitHub Actions.

## When to Use

- Creating new agentic workflows (`.github/workflows/*.md`)
- Configuring custom engines (Auggie, Claude)
- Debugging gh-aw compilation or runtime errors
- Setting up sandbox-disabled workflows with safe outputs
- Testing workflows from PR branches before merge

## File Structure

```text
.github/workflows/
  my-workflow.md        # Source (markdown + YAML frontmatter)
  my-workflow.lock.yml  # Compiled output (committed)
```

**Workflow cycle:** Edit `.md` → `gh aw compile` → commit both files

## Basic Structure

```markdown
---
description: What this workflow does
strict: false  # Required for custom engines
timeout-minutes: 20

on:
  workflow_dispatch:
    inputs:
      target_repo:
        description: 'Target repository'
        required: false

permissions:
  contents: read
  issues: read

sandbox:
  agent: false  # Required for custom engines

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
  threat-detection: false  # Required when sandbox.agent: false
  create-issue:
    title-prefix: "[workflow] "
    labels: [automated]
  noop:  # Always declare if prompt uses noop

tools:
  github:
    toolsets: [issues, pull_requests, repos]
    github-token: ${{ secrets.ORG_PAT }}

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

# Your Prompt Here

Instructions for the AI agent go below the frontmatter...
```

For a full, copy-paste-ready workflow that wires all of these patterns
together, see [examples/auggie-workflow.md](examples/auggie-workflow.md).

## Custom Engine Configuration (CRITICAL)

When using custom engines (Auggie instead of Copilot), these settings **must**
be paired:

| Setting | Value | Reason |
| --- | --- | --- |
| `sandbox.agent` | `false` | Custom engines run outside sandbox |
| `strict` | `false` | Required when sandbox disabled |
| `safe-outputs.threat-detection` | `false` | Requires sandbox |
| `network.allowed` | Include `api.augmentcode.com` | Augment API access |

**Required setup steps for Auggie:** see the `steps:` block in the Basic
Structure example above (Setup Augment Auth + Install Augment CLI).

## Safe Outputs

**CRITICAL:
Tool names must use hyphens, not underscores:**

| Correct | Incorrect |
| --- | --- |
| `create-issue` | `create_issue` |
| `create-pull-request` | `create_pull_request` |
| `add-comment` | `add_comment` |

- Always declare `noop:` if your prompt instructs agent to use noop
- JSON shape must be consistent:
  `{"type":
  "noop", "message":
  "..."}` not `{"noop":
  {...}}`

## Expression Safety

**Allowed in runtime imports:**

- `github.actor`, `github.repository`, `github.run_id`
- `github.event.issue.number`, `github.event.pull_request.number`
- `github.event.workflow_run.*` fields
- `inputs.*`, `env.*`, `steps.*`, `needs.*`

**NOT allowed (compilation fails):**

- `github.event_name` - Use `!github.event.workflow_run` to detect
  non-workflow_run events

## Testing from PR Branches

Workflows can't use `workflow_dispatch` until merged.
Use these workarounds:

**Option 1:
Temporary push trigger:**

```yaml
on:
  push:
    branches:
      - gh-aw/my-branch  # Remove before merge!
```

**Option 2:
Default test values:**

```yaml
env:
  RUN_ID: ${{ github.event.workflow_run.id || inputs.run_id || '12345' }}
  REPO: ${{ inputs.repository || 'org/default-test-repo' }}
```

## Error Reference

| Error | Fix |
| --- | --- |
| `sandbox.agent: false not allowed` | Add `strict: false` |
| `threat detection requires sandbox` | Add `threat-detection: false` to safe-outputs |
| `unauthorized expression: github.event_name` | Remove or use allowed expression |
| `tool not in allowlist` | Add to bash tools list |

## Development Cycle

1. Edit `.md` file
2. Run `gh aw compile` - check for errors
3. Commit both `.md` and `.lock.yml`
4. Push (use push trigger for PR branch testing)
5. Check:
   `gh run view <id> --log-failed`
6. Iterate until successful
7. Remove test triggers before merge

## Required Secrets

| Secret | Source | Purpose |
| --- | --- | --- |
| `AUGMENT_SESSION_AUTH` | `auggie token print` | JSON auth for Auggie |
| `ORG_PAT` | GitHub PAT | Cross-repo access |
