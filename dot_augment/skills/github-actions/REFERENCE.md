# GitHub Actions Reference

Extended patterns and templates for GitHub Actions.

## Reusable Workflows

**Define reusable workflow** (`.github/workflows/reusable-build.yml`):

```yaml
name: Reusable Build
on:
  workflow_call:
    inputs:
      node-version:
        type: string
        default: '20'
    secrets:
      NPM_TOKEN:
        required: false
    outputs:
      artifact-name:
        value: ${{ jobs.build.outputs.artifact }}

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      artifact: ${{ steps.upload.outputs.artifact-name }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
      - run: npm ci
      - run: npm run build
```

**Call reusable workflow:**

```yaml
jobs:
  call-build:
    uses: ./.github/workflows/reusable-build.yml
    with:
      node-version: '22'
    secrets: inherit  # Pass all secrets
```

## Composite Actions

**Define composite action** (`actions/setup-project/action.yml`):

```yaml
name: Setup Project
description: Install dependencies and setup environment

inputs:
  node-version:
    description: Node.js version
    default: '20'

outputs:
  cache-hit:
    description: Whether cache was hit
    value: ${{ steps.cache.outputs.cache-hit }}

runs:
  using: composite
  steps:
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}

    - id: cache
      uses: actions/cache@v4
      with:
        path: node_modules
        key: deps-${{ hashFiles('package-lock.json') }}

    - if: steps.cache.outputs.cache-hit != 'true'
      shell: bash
      run: npm ci
```

**Use composite action:**

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: ./actions/setup-project
    with:
      node-version: '22'
```

## Artifacts

```yaml
# Upload artifact
- uses: actions/upload-artifact@v4
  with:
    name: build-output
    path: dist/
    retention-days: 5
    if-no-files-found: error

# Download artifact (same workflow)
- uses: actions/download-artifact@v4
  with:
    name: build-output
    path: ./dist

# Download artifact (cross-workflow)
- uses: actions/download-artifact@v4
  with:
    name: build-output
    github-token: ${{ secrets.GITHUB_TOKEN }}
    repository: ${{ github.repository }}
    run-id: ${{ github.event.workflow_run.id }}
```

## Environment Deployments

```yaml
jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    environment:
      name: staging
      url: https://staging.example.com
    steps:
      - run: echo "Deploying to staging"

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://example.com
    steps:
      - run: echo "Deploying to production"
```

## Workflow Templates

### CI Template (Python)

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v5
      - run: uv run ruff check .
      - run: uv run ruff format --check .

  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python: ['3.11', '3.12', '3.13']
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v5
        with:
          python-version: ${{ matrix.python }}
      - run: uv run pytest
```

### Release Template

```yaml
name: Release
on:
  push:
    tags: ['v*']

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build
        run: npm run build

      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          files: dist/*
          generate_release_notes: true
```

## Action Selection Criteria

| Criteria | Prefer | Avoid |
|----------|--------|-------|
| **Maintainer** | Official (`actions/*`), verified publishers | Unknown authors |
| **Version** | Pinned SHA or version tag (`@v4`) | `@main` or `@latest` |
| **Activity** | Recently updated, responsive issues | Abandoned, stale |
| **Permissions** | Minimal, documented | Requests broad access |
| **Dependencies** | Few, audited | Many transitive deps |

**Pin to SHA for security-critical actions:**

```yaml
# Instead of @v4, use full SHA:
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
```

## Common Anti-Patterns

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| `permissions: write-all` | Excessive access | Set explicit minimal permissions |
| `@main` or `@latest` tags | Untested changes | Pin to version or SHA |
| Secrets in logs | Credential exposure | Use `add-mask` or avoid logging |
| No concurrency control | Wasted resources, race conditions | Add `concurrency:` block |
| Hardcoded versions | Maintenance burden | Use matrix or variables |
| No caching | Slow builds | Use `actions/cache` or setup-* cache |
| Ignoring exit codes | Silent failures | Check `$?` or use `set -e` |
| Large artifacts | Storage costs, slow downloads | Compress, set retention |

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| "Resource not accessible" | Missing permissions | Add `permissions:` block |
| act fails with image error | Missing Docker image | Use `-P` to specify image |
| Cache not restoring | Key mismatch | Check `hashFiles()` path |
| Job hangs | Waiting for input | Check for interactive commands |
| "No space left on device" | Runner disk full | Clean up with `rm -rf` or use larger runner |
| Matrix job fails | Missing exclude/include | Verify matrix combinations |
