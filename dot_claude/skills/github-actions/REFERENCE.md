# GitHub Actions - Reference Templates

## Reusable Workflows

```yaml
# .github/workflows/reusable-test.yml
on:
  workflow_call:
    inputs:
      python-version:
        type: string
        default: "3.12"
    secrets:
      PYPI_TOKEN:
        required: false

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ inputs.python-version }}
      - run: pip install -e ".[test]"
      - run: pytest
```

```yaml
# Caller workflow
jobs:
  test:
    uses: ./.github/workflows/reusable-test.yml
    with:
      python-version: "3.12"
    secrets:
      PYPI_TOKEN: ${{ secrets.PYPI_TOKEN }}
```

## Composite Actions

```yaml
# .github/actions/setup-python-env/action.yml
name: Setup Python Environment
description: Install Python and dependencies

inputs:
  python-version:
    description: Python version
    default: "3.12"
  install-extras:
    description: pip extras to install (e.g. "test,dev")
    default: ""

runs:
  using: composite
  steps:
    - uses: actions/setup-python@v5
      with:
        python-version: ${{ inputs.python-version }}
        cache: pip

    - name: Install dependencies
      shell: bash
      run: |
        pip install -e ".[$(echo '${{ inputs.install-extras }}')]"
```

```yaml
# Usage:
- uses: ./.github/actions/setup-python-env
  with:
    python-version: "3.12"
    install-extras: "test,dev"
```

## Artifact Handling

```yaml
# Upload artifacts
- uses: actions/upload-artifact@v4
  with:
    name: test-results-${{ matrix.python-version }}
    path: |
      reports/
      coverage.xml
    retention-days: 7
    if-no-files-found: error

# Download in another job
- uses: actions/download-artifact@v4
  with:
    name: test-results-3.12
    path: reports/

# Download all artifacts
- uses: actions/download-artifact@v4
  with:
    path: all-artifacts/
    merge-multiple: true
```

## Environment and Deployment Gates

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://myapp.example.com
    steps:
      - run: echo "Deploying to production"
```

```yaml
# Deployment with OIDC (no long-lived secrets)
jobs:
  deploy-aws:
    runs-on: ubuntu-latest
    environment: production
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_ROLE_ARN }}
          aws-region: us-east-1
      - run: aws s3 sync ./dist s3://my-bucket/
```

## Complete Workflow Templates

### Python CI

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        python-version: ["3.11", "3.12"]

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
          cache: pip

      - name: Install dependencies
        run: pip install -e ".[test]"

      - name: Run linters
        run: |
          ruff check .
          ruff format --check .

      - name: Run tests
        run: pytest --cov=src --cov-report=xml

      - uses: codecov/codecov-action@v4
        with:
          file: coverage.xml
```

### Release Workflow

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write
  id-token: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Build package
        run: |
          pip install build
          python -m build

      - name: Publish to PyPI
        uses: pypa/gh-action-pypi-publish@release/v1

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          generate_release_notes: true
          files: dist/*
```

### Docker Build and Push

```yaml
name: Docker

on:
  push:
    branches: [main]
    tags: ['v*']

permissions:
  contents: read
  packages: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: docker/setup-buildx-action@v3

      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/metadata-action@v5
        id: meta
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=sha,prefix=sha-

      - uses: docker/build-push-action@v5
        with:
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

## Action Selection Criteria

| Need | Action | Notes |
|------|--------|-------|
| Checkout | `actions/checkout@v4` | Always use v4+ |
| Python | `actions/setup-python@v5` | Use `cache: pip` |
| Node | `actions/setup-node@v4` | Use `cache: npm` |
| Java | `actions/setup-java@v4` | |
| Go | `actions/setup-go@v5` | |
| AWS credentials | `aws-actions/configure-aws-credentials@v4` | Prefer OIDC over secrets |
| Docker login | `docker/login-action@v3` | |
| Cache | `actions/cache@v4` | Or use setup-* built-in cache |
| Artifacts | `actions/upload-artifact@v4` | |

## Common Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| `uses: actions/checkout@main` | Unpinned, supply chain risk | Pin to SHA or version tag |
| `permissions: write-all` | Over-privileged | Use minimum required permissions |
| Secrets in `run:` step | Exposed in logs | Use `env:` with secret value |
| `${{ github.event.*.body }}` in `run:` | Script injection | Use env var intermediary |
| No `fail-fast: false` in matrix | Cancels all on first fail | Add `fail-fast: false` |
| No `concurrency:` on PR workflows | Wastes CI minutes | Add concurrency group |
| `if: always()` on expensive steps | Runs even when cancelled | Use `if: success() or failure()` |
