# GitHub Actions -- Reference

Lookup tables and complete patterns. Read the sections you need; do not load
this wholesale. Facts current as of 2026.

## Current action versions

Pin first-party actions to the major tag; pin third-party actions to a full
SHA (see SKILL.md rule 1).

| Action | Pin to | Notes |
| --- | --- | --- |
| `actions/checkout` | `@v6` | v6 needs runner >= 2.329.0; v5 = Node 24 |
| `actions/setup-node` | `@v6` | v6 = Node 24; `cache: 'npm' \| 'yarn' \| 'pnpm'` |
| `actions/setup-python` | `@v6` | v6 = Node 24; `cache: 'pip' \| 'pipenv' \| 'poetry'` |
| `actions/setup-java` | `@v5` | `distribution:` required; `cache: maven\|gradle\|sbt` |
| `actions/setup-go` | `@v5` | built-in module/build caching |
| `actions/cache` | `@v5` | v5 = Node 24 |
| `actions/upload-artifact` | `@v4` | v3 hard-disabled 2025-01-30; pin v4 (v5+ are Node-24 bumps) |
| `actions/download-artifact` | `@v4` | matches upload major; v4 needs unique artifact names |
| `actions/configure-pages` | `@v6` | |
| `actions/upload-pages-artifact` | `@v5` | |
| `actions/deploy-pages` | `@v5` | needs `actions: read` |
| `aws-actions/configure-aws-credentials` | `@v4` | prefer OIDC over static keys |
| `docker/setup-buildx-action` | `@v3` | |
| `docker/login-action` | `@v3` | |
| `docker/build-push-action` | `@v6` | |
| `docker/metadata-action` | `@v5` | |

**upload/download-artifact v4 breaking changes** (vs v3, hard-cutoff 2025-01-30):

- Up to 98% faster; artifacts are **immutable** after creation.
- **Cannot upload to the same artifact name twice in one run.** Matrix jobs MUST
  use unique names: `name: binary-${{ matrix.os }}`.
- Artifacts no longer auto-merge across jobs -- use the separate `merge` action
  or `download-artifact` with `merge-multiple: true`.

## Runner labels

Two common assumptions are now wrong: `windows-latest` = Server **2025**;
`macos-latest` = **macOS 15 on Apple silicon** (not Intel).

| Label | Maps to |
| --- | --- |
| `ubuntu-latest` / `ubuntu-24.04` | Ubuntu 24.04 |
| `ubuntu-22.04` | Ubuntu 22.04 |
| `ubuntu-24.04-arm` / `ubuntu-22.04-arm` | arm64 Linux |
| `windows-latest` / `windows-2025` | Windows Server 2025 |
| `windows-2022` | Windows Server 2022 |
| `windows-11-arm` | Windows 11 arm64 |
| `macos-latest` / `macos-15` | macOS 15, Apple silicon |
| `macos-14` | macOS 14, Apple silicon |
| `macos-15-intel` | Intel macOS (use `-intel` suffix for Intel now) |

GitHub-hosted specs: public-repo Linux/Windows = 4 vCPU / 16 GB; private free
tier = 2 vCPU / 8 GB; macOS arm = 3 vCPU / 7 GB. Larger runners (Team/Enterprise)
add static IPs, runner groups, autoscaling, GPU SKUs.

```yaml
runs-on: ubuntu-latest                      # single label
runs-on: [self-hosted, linux, x64, gpu]     # array -- must match ALL labels
runs-on:                                     # group + labels (larger/self-hosted)
  group: ubuntu-runners
  labels: [ubuntu-22.04-16core]
```

## GITHUB_TOKEN permission scopes

Each takes `read` | `write` | `none` (`write` implies `read`). **Specifying any
scope sets all unspecified scopes to `none`.**

```yaml
permissions:
  actions: read|write|none
  attestations: read|write|none
  checks: read|write|none
  contents: read|write|none
  deployments: read|write|none
  id-token: write|none           # write|none only -- required for OIDC
  issues: read|write|none
  models: read|none              # read|none only
  discussions: read|write|none
  packages: read|write|none
  pages: read|write|none
  pull-requests: read|write|none
  security-events: read|write|none
  statuses: read|write|none
```

Shorthand: `permissions: {}` (deny all), `permissions: read-all`,
`permissions: write-all` (avoid). Secrets cannot be used in `if:` -- bind to a
job-level `env:` var first. For scopes `GITHUB_TOKEN` can't grant, use a GitHub
App installation token or a PAT secret.

## Untrusted contexts (script-injection sources)

Never interpolate these into a `run:` block -- route through `env:` (SKILL.md
rule 3). Verified list from GitHub Security Lab:

```text
github.event.issue.title              github.event.issue.body
github.event.pull_request.title       github.event.pull_request.body
github.event.comment.body             github.event.review.body
github.event.pages.*.page_name        github.event.commits.*.message
github.event.head_commit.message      github.event.head_commit.author.email
github.event.head_commit.author.name  github.event.commits.*.author.email
github.event.commits.*.author.name    github.event.pull_request.head.ref
github.event.pull_request.head.label  github.event.pull_request.head.repo.default_branch
github.head_ref
```

Also injection vectors because they flow into the above: **branch names**
(`zzz";echo${IFS}"pwned";#`) and **email addresses**
(`` `echo${IFS}hello`@x.com ``).

## Fork-safe two-workflow pattern

`pull_request_target` with secrets must never execute fork code. Split untrusted
build from privileged follow-up.

```yaml
# Workflow 1 -- untrusted: on: pull_request (read-only token, NO secrets)
name: Receive PR
on: pull_request
permissions:
  contents: read
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6     # safe: read-only, no secrets in scope
      - run: ./build.sh
      - run: |
          mkdir -p ./pr
          echo "${{ github.event.number }}" > ./pr/NR
      - uses: actions/upload-artifact@v4
        with: { name: pr, path: pr/ }
```

```yaml
# Workflow 2 -- privileged: on: workflow_run (read/write token + secrets)
name: Comment on PR
on:
  workflow_run:
    workflows: ["Receive PR"]
    types: [completed]
permissions:
  pull-requests: write
jobs:
  comment:
    if: >
      github.event.workflow_run.event == 'pull_request' &&
      github.event.workflow_run.conclusion == 'success'
    runs-on: ubuntu-latest
    steps:
      # download the artifact and treat its contents as untrusted DATA
      # (reading a PR number is fine; executing a built binary is not)
      - run: echo "privileged work here"
```

Rules: use `pull_request_target` only for passive triage (label/comment). Never
check out PR head under it. Label-gating is racy (attacker pushes after
approval). Same-repo-only guard for sensitive steps:
`if: github.event.pull_request.head.repo.full_name == github.repository`.

## Required-check-skip remediation

A required check behind a `paths:` filter leaves the PR stuck. Two fixes:

**A -- always-run gate, filter inside the job** (preferred):

```yaml
on: pull_request          # no paths filter -- always runs -> always reports
jobs:
  ci:
    name: build           # the required check name
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: dorny/paths-filter@<sha>   # pin third-party
        id: changes
        with:
          filters: |
            src:
              - 'src/**'
      - if: steps.changes.outputs.src == 'true'
        run: ./build-and-test.sh
      - if: steps.changes.outputs.src != 'true'
        run: echo "no source changes -- pass"
```

**B -- companion skip-workflow with the SAME job name** (branch protection keys
on the check/job name, not the workflow file):

```yaml
# ci.yml         -> on: pull_request: paths: ['src/**'],  job name: build
# ci-skip.yml    -> on: pull_request: paths-ignore: ['src/**'], job name: build (trivially passes)
```

## Reusable workflows vs composite actions

- **Composite action** = steps bundled as a single step **inside a job** (same
  runner). Share steps within a job.
- **Reusable workflow** = whole **jobs** invoked from another workflow (own
  runners). Share pipelines/jobs/secrets.
- Nesting limit is **10** (not 4).

### Reusable workflow

```yaml
# .github/workflows/reusable.yml
on:
  workflow_call:
    inputs:
      config-path: { required: true, type: string }   # type: boolean|number|string
    secrets:
      token: { required: true }
    outputs:
      firstword: { value: ${{ jobs.triage.outputs.out1 }} }
jobs:
  triage:
    runs-on: ubuntu-latest
    outputs: { out1: ${{ steps.s.outputs.fw }} }
    steps:
      - id: s
        run: echo "fw=hello" >> "$GITHUB_OUTPUT"
```

```yaml
# caller -- uses: sits on the JOB, not in steps
jobs:
  call-local:
    uses: ./.github/workflows/reusable.yml          # local: relative path, NO @ref
  call-remote:
    uses: octo-org/repo/.github/workflows/reusable.yml@<sha>   # cross-repo needs @ref
    with: { config-path: .github/labeler.yml }
    secrets: inherit                                # passes all secrets, ONE level down
```

### Composite action

```yaml
# .github/actions/greet/action.yml
name: Greet
inputs:
  who: { required: true, default: World }
outputs:
  rand: { value: ${{ steps.r.outputs.rand }} }
runs:
  using: composite
  steps:
    - run: echo "Hello $INPUT_WHO"
      shell: bash                       # shell REQUIRED on every composite run step
      env: { INPUT_WHO: ${{ inputs.who }} }
    - id: r
      run: echo "rand=$RANDOM" >> "$GITHUB_OUTPUT"
      shell: bash
    - run: echo "$GITHUB_ACTION_PATH" >> "$GITHUB_PATH"   # so bundled scripts resolve
      shell: bash
# consume:  - uses: ./.github/actions/greet  (as a step)
```

## Matrix: dynamic from JSON

```yaml
jobs:
  define-matrix:
    runs-on: ubuntu-latest
    outputs:
      colors: ${{ steps.colors.outputs.colors }}
    steps:
      - id: colors
        run: echo 'colors=["red","green","blue"]' >> "$GITHUB_OUTPUT"  # valid JSON
  build:
    needs: define-matrix
    runs-on: ubuntu-latest
    strategy:
      matrix:
        color: ${{ fromJSON(needs.define-matrix.outputs.colors) }}
    steps:
      - run: echo "${{ matrix.color }}"
```

`include`/`exclude`: `exclude` is processed first; `include` adds keys to
matching combos or appends new combos. Max **256 jobs** per matrix per run.

## Caching details

```yaml
- uses: actions/cache@v5
  id: cache
  with:
    path: |
      ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
- if: steps.cache.outputs.cache-hit != 'true'
  run: npm ci
```

- `key`: exact match -> `cache-hit == 'true'`. `restore-keys`: ordered
  prefix-match fallbacks; a partial restore reports `cache-hit == 'false'`.
- **Limits:** 10 GB total per repo; LRU eviction; entries unused for 7 days are
  removed. Caches are scoped to the writing branch + default branch (no
  cross-branch sharing) -- a security boundary: never restore PR-written caches
  into a privileged job.

## OIDC (no long-lived cloud secrets)

```yaml
permissions:
  id-token: write
  contents: read
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/my-gha-role
          aws-region: us-east-1
```

Exchanges a short-lived GitHub-signed token for cloud creds; no stored keys.
Caveat: custom OIDC claims are unavailable in AWS.

## Artifact attestations (build provenance)

```yaml
permissions:
  id-token: write
  contents: read
  attestations: write
  # packages: write   # add for container images
steps:
  - uses: actions/attest-build-provenance@<sha>
    with:
      subject-path: dist/*
```

Verify: `gh attestation verify dist/app -R ORG/REPO` (containers use `oci://...`).

## Expressions and functions

**Operators:** `( ) [ ] . ! < <= > >= == != && ||`. **Falsy:** `false`, `0`,
`-0`, `""`, `null`. String comparison is **case-insensitive**. Outputs are
always strings -- compare to `'true'`, never treat as native bool.

| Function | Example |
| --- | --- |
| `contains(search, item)` | substring or array membership |
| `startsWith(s, pre)` / `endsWith(s, suf)` | case-insensitive |
| `format('{0} {1}', a, b)` | escape literal braces as `{{` / `}}` |
| `join(array, sep)` | default sep `,` |
| `toJSON(x)` / `fromJSON(s)` | serialize / parse; `fromJSON` also for numeric compares |
| `hashFiles('**/lock')` | SHA-256 over matched files; empty string if none |
| `success()` `failure()` `cancelled()` `always()` | status checks; `success()` is implicit on any `if:` without a status function |

Object filter: `fruits.*.name` -> array of each `name`.

**Workflow commands** (in `run:`):

```bash
echo "k=v" >> "$GITHUB_OUTPUT"          # producing step needs id:
echo "K=v" >> "$GITHUB_ENV"             # later steps; can't set NODE_OPTIONS or GITHUB_*/RUNNER_*
echo "$HOME/bin" >> "$GITHUB_PATH"
echo "### Summary" >> "$GITHUB_STEP_SUMMARY"   # 1 MiB/step, 20 summaries/job
echo "::add-mask::$SECRET"              # before printing; masked value can't become an output
echo "::error file=app.js,line=10::message"
echo "::warning::message" ; echo "::notice::message"
echo "::group::Title" ; echo "::endgroup::"
echo "::debug::message"                 # needs ACTIONS_STEP_DEBUG=true
```

## Secrets handling

- Fork `pull_request` runs and Dependabot runs get **no** regular secrets; only
  a read-only `GITHUB_TOKEN`.
- Masking is **exact-substring**: Base64/JWT/structured-JSON-field secrets are
  NOT masked. Store one secret per atomic value; `::add-mask::` any derived value.
- Never pass secrets as CLI args (visible via `ps`); use `env:` or STDIN.
- Large secret >48 KB: commit a `.gpg` file, store only the passphrase. Note
  GitHub does NOT redact values you decrypt at runtime.

## Self-hosted runner risk

- Not ephemeral clean VMs -- can be persistently compromised by untrusted code.
- **Almost never use on public repos** (and private repos with forking): any
  fork PR can compromise the runner and harvest secrets.
- Use **JIT ephemeral runners** (`./run.sh --jitconfig ...`) -- one job then
  removed. Use runner groups as blast-radius boundaries. Block cloud metadata
  endpoints.

## Triggers (on:)

| Trigger | Use | Example filter |
| --- | --- | --- |
| `push` | commits | `branches: [main]`, `tags: ['v*']`, `paths: ['src/**']` |
| `pull_request` | PR events; fork PRs get no secrets | `types: [opened, synchronize]` |
| `pull_request_target` | privileged PR triage (see rule 4) | runs in base context |
| `workflow_dispatch` | manual | `inputs: { version: { type: string } }` |
| `schedule` | cron | `cron: '0 0 * * *'` |
| `workflow_call` | reusable workflow | called by others |
| `workflow_run` | after another workflow | `workflows: [...]; types: [completed]` |
| `repository_dispatch` | external API | `types: [deploy]` |

Path/branch filters: `paths` runs if >= 1 changed file matches; `paths-ignore`
skips if all changed files match. Cannot combine `paths` + `paths-ignore` (use
`!` negation within one). `paths` is not evaluated on tag pushes.

## Complete templates

### Python CI

```yaml
name: CI
on:
  push: { branches: [main] }
  pull_request: { branches: [main] }
permissions:
  contents: read
concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    strategy:
      fail-fast: false
      matrix:
        python-version: ["3.11", "3.12", "3.13"]
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-python@v6
        with:
          python-version: ${{ matrix.python-version }}
          cache: pip
      - run: pip install -e ".[test]"
      - run: ruff check . && ruff format --check .
      - run: pytest --cov=src --cov-report=xml
      - uses: codecov/codecov-action@<sha>   # pin third-party
        with: { file: coverage.xml }
```

### Release (tag-triggered, OIDC PyPI publish)

```yaml
name: Release
on:
  push: { tags: ['v*'] }
permissions:
  contents: write       # create the GitHub Release
  id-token: write       # trusted publishing to PyPI (no token secret)
jobs:
  release:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-python@v6
        with: { python-version: "3.12" }
      - run: pip install build && python -m build
      - uses: pypa/gh-action-pypi-publish@release/v1
      - uses: softprops/action-gh-release@<sha>   # pin third-party
        with:
          generate_release_notes: true
          files: dist/*
```

### Docker build + push (GHCR)

```yaml
name: Docker
on:
  push: { branches: [main], tags: ['v*'] }
permissions:
  contents: read
  packages: write
concurrency:
  group: docker-${{ github.ref }}
  cancel-in-progress: true
jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v6
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
      - uses: docker/build-push-action@v6
        with:
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### Deployment environment gate

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    timeout-minutes: 20
    environment:               # required-reviewer protection rules apply here
      name: production
      url: https://myapp.example.com
    concurrency:
      group: deploy-production
      cancel-in-progress: false   # never cancel a half-done deploy
    steps:
      - run: echo "deploy"
```
