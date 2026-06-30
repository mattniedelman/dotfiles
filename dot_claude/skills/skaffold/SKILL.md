---
name: skaffold
description: >
  Use when working with Skaffold -- writing skaffold.yaml, running the dev loop,
  configuring builds, profiles, file sync, CI/CD pipelines, or debugging
  Skaffold configuration and deployment issues.
paths: "skaffold.yaml,skaffold.*.yaml"
---

# Skaffold Reference

## Quick Reference: What Agents Get Wrong

| Wrong assumption | Correct behavior |
| --- | --- |
| Use `apiVersion: skaffold/v4beta6` | Current schema is `skaffold/v4beta14`. Use `skaffold fix` to migrate. Do NOT lexically sort versions -- `v4beta13` < `v4beta4` alphabetically; compare numerically. |
| Manifests (rawYaml/kustomize/helm) go under `deploy:` | In Skaffold v2 the top-level **`manifests:`** section holds what to render; `deploy:` only applies. See "Render vs Deploy Split" below -- this is the #1 thing agents get wrong. |
| Helm image injection uses `artifactOverrides`/`imageStrategy` | Both **removed** in v2. Use `setValueTemplates` with `{{.IMAGE_FULLY_QUALIFIED_<name>}}` style vars instead. |
| `deploy.kustomize` is a deployer | Kustomize is **render-only** (`manifests.kustomize.paths`). There is no `deploy.kustomize`; you render then `deploy.kubectl`. |
| File sync speeds up `skaffold run` | File sync only works with `skaffold dev` and `skaffold debug`, never `run`/`build`/`deploy`. |
| `skaffold debug` rebuilds on file change like `dev` | `debug` **disables** auto build/sync/deploy by default to avoid killing debug sessions. Re-enable with `--auto-build`, `--auto-sync`, `--auto-deploy`. |
| `skaffold apply` honors the configured deployer | `apply` **always uses kubectl** regardless of deployer config; only a small key subset is honored. |
| Profile kube-context activation uses glob regex | `kubeContext` activation takes a **regexp** (`gke_.*`), prefix `!` negates. Not a shell glob. |
| `portForwards` is the YAML key | The key is `portForward` (singular). |
| `skaffold dev` is the starting point | Run `skaffold diagnose` first when config looks wrong. |
| Tagging is automatic and always works | Default tagger is `gitCommit`; uncommitted/generated files add a `-dirty` suffix (set `ignoreChanges: true`). In CI without full git history, configure `inputDigest` or `envTemplate`. |
| `sha256` tagger produces a sha256 tag | It tags `latest`; the real digest is appended at deploy. For content-based tags use `inputDigest`. |

---

## skaffold.yaml Structure

```yaml
apiVersion: skaffold/v4beta14  # always use the current version
kind: Config
metadata:
  name: my-app

build:
  artifacts: ['...']
  local:
    concurrency: 0  # 0 = all artifacts built in parallel (local default is 1)

manifests:        # WHAT to render: rawYaml / kustomize / helm
  rawYaml: ['...']

deploy:           # HOW to apply what was rendered: kubectl / helm / kpt / cloudrun
  kubectl: {}

portForward: ['...']  # singular, not portForwards

profiles: ['...']
```

Top-level keys (v4beta14): `apiVersion`, `kind`, `metadata`, `build`, `test`,
`manifests`, `deploy`, `profiles`, `customActions`, `verify`, `portForward`,
`resourceSelector`, `requires`.
Multiple configs in one file are separated by `---`.

Run `skaffold fix --overwrite` to migrate older configs to the current schema.
`skaffold fix` flags helm/kpt usage for manual attention -- review the result.

---

## Render vs Deploy Split (Skaffold v2 / v4beta)

**This is the #1 mistake.** Skaffold v2 split the old single `deploy` phase into
two: **`manifests:`** (render -- hydrate/template manifests) and **`deploy:`**
(apply the hydrated manifests). What you list to be rendered lives under the
top-level `manifests:` section, NOT under `deploy:`.

| Tool | Where it goes | Notes |
| --- | --- | --- |
| Raw YAML | `manifests.rawYaml: [k8s-*.yaml]` | replaces the v1 `deploy.kubectl.manifests` |
| Kustomize | `manifests.kustomize.paths: [...]` | **render-only** -- there is no `deploy.kustomize`. Kustomize CLI must be preinstalled. |
| Helm (template) | `manifests.helm.releases` | runs `helm template`; pair with `deploy.helm` or `deploy.kubectl` to apply |
| Helm (install) | `deploy.helm.releases` | runs `helm install`; the deployer, not the renderer |

```yaml
# Raw manifests: render with manifests:, apply with deploy.kubectl
manifests:
  rawYaml:
    - k8s-*.yaml
deploy:
  kubectl: {}
```

`deploy:` sub-keys (v4beta14): `kubectl`, `helm`, `kpt`, `docker`, `cloudrun`,
`kubeContext`, `logs`, `statusCheck`, `statusCheckDeadlineSeconds`,
`tolerateFailuresUntilDeadline`.

**Removed in v2:** `artifactOverrides` and `imageStrategy` (helm). Inject built
image tags with `setValueTemplates` instead (see Helm section below).

---

## Helm

For **deploy via `helm install`** put releases under `deploy.helm`; for
**GitOps render via `helm template`** put them under `manifests.helm`.

```yaml
build:
  artifacts:
    - image: api
    - image: worker
deploy:
  helm:
    releases:
      - name: my-app
        chartPath: charts/my-app
        # Inject built image refs -- replaces removed artifactOverrides.
        # IMAGE_FULLY_QUALIFIED_<name> = repo:tag@digest for that artifact.
        setValueTemplates:
          api.image: "{{.IMAGE_FULLY_QUALIFIED_api}}"
          worker.image: "{{.IMAGE_FULLY_QUALIFIED_worker}}"
```

Template image vars (artifact name with `/` and `-` replaced by `_`):
`IMAGE_NAME_<name>`, `IMAGE_REPO_<name>`, `IMAGE_TAG_<name>`,
`IMAGE_DIGEST_<name>`, and the combined `IMAGE_FULLY_QUALIFIED_<name>`.
For a single (first) artifact the unsuffixed `IMAGE_NAME`/`IMAGE_TAG`/
`IMAGE_DIGEST` are available.

---

## GitOps: Render for Argo CD / Flux

`skaffold render` hydrates manifests (resolving image tags to immutable
`repo:tag@digest` references) without deploying -- commit the output to a
GitOps repo.

```bash
# Hydrate manifests to a file for a GitOps repo
skaffold render -p prod --output manifests/rendered.yaml

# Resolve digests from the remote registry rather than the local daemon
skaffold render --digest-source=remote -o rendered.yaml
```

Note: the removed `skaffold deploy --render-only` / `--skip-render` flags no
longer exist -- use `skaffold render`.

---

## Artifact Image Names and Registries

**Use short names + `default-repo` instead of hardcoding full registry paths.**

```yaml
# Good -- portable across registries
build:
  artifacts:
    - image: api
    - image: worker

# Bad -- hardcoded to a specific registry
build:
  artifacts:
    - image: us-docker.pkg.dev/my-project/my-repo/api
```

Set `default-repo` at runtime or globally:

```bash
# At runtime
skaffold dev -d us-docker.pkg.dev/my-project/my-repo

# Globally (persists to ~/.skaffold/config)
skaffold config set --global default-repo us-docker.pkg.dev/my-project/my-repo
```

For **GKE + Artifact Registry** (modern, not GCR):

```bash
gcloud auth configure-docker us-docker.pkg.dev
# Repo format: REGION-docker.pkg.dev/PROJECT/REPOSITORY
```

For **local clusters** (minikube, kind, k3d), skip the push entirely:

```bash
skaffold config set --kube-context CONTEXT_NAME local-cluster true
```

---

## Core Commands

| Command | When to use |
| --- | --- |
| `skaffold dev` | Inner dev loop -- watch, build, deploy, tail logs, cleanup on exit |
| `skaffold run` | One-shot build + deploy (no watch, no auto-cleanup) |
| `skaffold debug` | Dev loop with debugger ports exposed per language |
| `skaffold build -q --file-output=tags.json` | CI: build only, capture image tags as JSON |
| `skaffold deploy -a tags.json` | CI: deploy pre-built images from a previous build step |
| `skaffold render -o manifests.yaml` | GitOps: produce hydrated Kubernetes manifests |
| `skaffold verify -a tags.json` | Run post-deploy verification/integration test containers |
| `skaffold apply manifests.yaml` | Apply hydrated manifests (ALWAYS via kubectl, ignores deployer config) |
| `skaffold diagnose` | Print effective config and detect issues |
| `skaffold fix --overwrite` | Migrate skaffold.yaml to the current schema version |
| `skaffold delete` | Remove all resources Skaffold deployed |

**CI/CD pattern** (split build from deploy):

```bash
# Build step
skaffold build -q --file-output=tags.json

# Deploy step (separate job, different credentials, etc.)
skaffold deploy -a tags.json
```

---

## Profiles

Profiles activate automatically by kube-context, command, or environment
variable.
They can patch, replace, or add to the base config using
[strategic merge patch](https://skaffold.dev/docs/environment/profiles/).

```yaml
profiles:
  - name: prod
    activation:
      - kubeContext: gke_.*  # REGEXP (prefix ! to negate), not a shell glob
      - env: CI=true  # environment variable KEY=VALUE
      - command: run  # the skaffold subcommand in use
    build:
      googleCloudBuild:
        projectId: my-project
    # patches use JSON Patch (op/path/value):
    patches:
      - op: replace
        path: /build/artifacts/0/docker/dockerfile
        value: Dockerfile.prod
```

**Activation logic**: a profile activates if ANY activation block matches
(OR'd); within one block, ALL criteria must match (AND'd). `kubeContext` is a
**regexp** -- use `gke_.*`, not `gke_*`. Force/disable from the CLI with
`-p name` or `-p -name`.

---

## File Sync (dev and debug only)

File sync copies changed files directly into running containers, bypassing
rebuild. Three modes -- you cannot mix them in one artifact:

```yaml
build:
  artifacts:
    - image: api
      sync:
        infer: ["**/*.py"]   # dest inferred from ADD/COPY in the Dockerfile
    - image: web
      sync:
        manual:              # explicit src -> dest mapping
          - src: "src/**/*.js"
            dest: /app/src
    - image: svc
      sync:
        auto: true           # Jib & Buildpacks only (default-on for Buildpacks)
```

**Rules:**

- Sync applies only to `skaffold dev` and `skaffold debug` -- never `run`,
  `build`, `test`, or `deploy`. Those always do a full rebuild.
- `infer` reads `ADD`/`COPY` from the Dockerfile (last stage only for
  multi-stage) to pick the destination.
- `auto` is supported only by Jib and Buildpacks; it is on by default for
  Buildpacks (disable with `sync: {auto: false}`).
- Syncing only handles modified/added files. A **deletion triggers a full
  rebuild**.

---

## Port Forwarding

```yaml
portForward:  # singular key
  - resourceType: deployment
    resourceName: api
    namespace: default
    port: 8080
    localPort: 8080
```

`--port-forward` takes resource-class values:

- `off` -- disabled
- `user` -- only resources defined in `portForward`
- `services` -- also forwards all Services
- `debug` -- debug ports opened by `skaffold debug`
- `pods` -- all `containerPort`s on pods of Skaffold-built images

**Per-command defaults differ** (the non-obvious part):

- `skaffold dev` -> `user`; with `--port-forward` -> `user,services`
- `skaffold debug` -> `user,debug`; with `--port-forward` -> `user,services,debug`
- `skaffold run` / `skaffold deploy` -> `off`; with `--port-forward` -> `user,services`

Skaffold only auto-matches local ports for remote ports `> 1023`. For Docker
deployments `resourceType` must be `container`.

---

## Tag Policy for CI

The default `gitCommit` tagger derives tags from git in the artifact context.
Two CI pitfalls:

1. **Uncommitted/generated files add a `-dirty` suffix.** A CI checkout that
   writes files before building yields dirty tags. Suppress with
   `gitCommit: {ignoreChanges: true}`.
2. **Shallow clones / detached HEAD** can break `gitCommit`. Either restore
   history (`git fetch --unshallow --tags`) or switch tagger.

```yaml
build:
  tagPolicy:
    inputDigest: {}   # tag from a digest of source files -- no git needed
    # or:
    # envTemplate:
    #   template: "{{.IMAGE_NAME}}:{{.BUILD_ID}}"  # any startup env var
```

Tagger options: `gitCommit` (default), `inputDigest`, `envTemplate`,
`dateTime`, `customTemplate`, `sha256`. Note `sha256` does NOT emit a sha256
tag -- it tags `latest` and appends the digest at deploy; for content-based
tags use `inputDigest`. `skaffold build --dry-run` prints the tags that would
be used without building.

---

## Verify (post-deploy / integration tests)

`skaffold verify` runs test containers AFTER the deploy stage and monitors them
for success -- the modern way to run integration tests against a live deploy.
Distinct from `test` (which runs at build time against images).

```yaml
verify:
  - name: integration-test
    container:
      name: integration-test
      image: integration-test          # a Skaffold-built or standalone image
      command: ["pytest", "tests/integration"]
    executionMode:
      kubernetesCluster: {}            # run as a K8s Job (omit = run locally via docker)
```

Run with `skaffold verify -a tags.json`. Exit code 0 = all passed, 1 = a
failure -- suitable for CI gating. Default execution mode runs the container
locally via the docker CLI; `kubernetesCluster: {}` runs it as a Job in-cluster.

---

## Lifecycle Hooks

Run commands around build/sync/deploy phases. `host` hooks run on the Skaffold
machine; `container` hooks exec inside a target container.

```yaml
# Run a DB migration in-cluster AFTER deploy.
# IMPORTANT: deploy hooks nest UNDER the deployer key (deploy.kubectl.hooks),
# not as a sibling of it.
deploy:
  kubectl:
    hooks:
      after:
        - container:
            podName: api-*           # glob/prefix patterns allowed
            containerName: api
            command: ["python", "manage.py", "migrate"]
# Or a host-side command before build (nests under the artifact):
build:
  artifacts:
    - image: api
      hooks:
        before:
          - command: ["sh", "-c", "./scripts/gen-proto.sh"]
            os: [darwin, linux]
```

- Phases: `build` (host only), `sync` (host + container), `deploy` (host +
  container). Deploy `after` container commands run only after status checks pass.
- Deploy container hooks need `podName` + `containerName` (the target can't be
  inferred).
- Hook nesting: build hooks go under `build.artifacts[].hooks`, sync under
  `sync.hooks`, deploy under the deployer (`deploy.kubectl.hooks`). The legacy
  `deploy.helm` deployer does not expose container hooks the way `kubectl` does
  -- run migrations as a host hook or a Helm chart hook/Job instead.

---

## Status Check

Enabled by default after deploy -- waits for Deployments/StatefulSets/Pods to
become ready. Disable with `--status-check=false`.

```yaml
deploy:
  statusCheckDeadlineSeconds: 600        # default 10 min
  tolerateFailuresUntilDeadline: true    # wait full deadline instead of exiting on first failure (flaky CI)
```

`--iterative-status-check=true` checks after each deployer instead of once at
the end.

---

## Debugging

```bash
# Attach a language-aware debugger (adds debug ports per language runtime).
# NOTE: debug DISABLES auto build/sync/deploy by default to protect the
# debug session -- re-enable with --auto-build / --auto-sync / --auto-deploy.
skaffold debug

# Inspect effective config for a profile
skaffold diagnose --yaml-only -p prod

# Bootstrap skaffold.yaml by auto-detecting Dockerfiles and manifests
skaffold init

# Show detected artifacts without writing a file
skaffold init --analyze
```

`skaffold init` walks the directory tree, finds Dockerfiles and existing
Kubernetes manifests, and generates a starter `skaffold.yaml`.
Always review its output before using it directly.

---

## Rationalization Table

| If you're thinking... | Reality |
| --- | --- |
| "v4beta6 is recent enough" | Current is `v4beta14`. Run `skaffold fix` to migrate; don't lexically compare versions. |
| "Manifests go under `deploy:`" | In v2 they go under top-level `manifests:` (rawYaml/kustomize/helm). `deploy:` only applies them. |
| "I'll use `artifactOverrides` to inject the image into Helm" | Removed in v2. Use `setValueTemplates` with `{{.IMAGE_FULLY_QUALIFIED_<name>}}`. |
| "`deploy.kustomize` will apply my kustomization" | Kustomize is render-only (`manifests.kustomize.paths`); apply with `deploy.kubectl`. |
| "I'll just hardcode `gcr.io/...` in the image name" | Use `default-repo`. Hardcoded paths break portability and make profile switching harder. |
| "File sync will speed up my `skaffold run` in CI" | Sync is dev/debug only. CI should use `skaffold build` + `skaffold deploy` split. |
| "I need to set the tag policy manually" | Default `gitCommit` works locally. Switch to `inputDigest` only when CI lacks git history; watch for `-dirty` suffixes. |
| "The profile `kubeContext` takes a glob" | It takes a **regexp** -- `gke_.*`, not `gke_*`. Prefix `!` to negate. |
| "`skaffold debug` rebuilds on save like `dev`" | debug disables auto build/sync/deploy by default; pass `--auto-build`/`--auto-sync`/`--auto-deploy`. |
| "`skaffold apply` uses my configured deployer" | `apply` always uses kubectl regardless of the deployer in config. |
| "I'll use lifecycle hooks / `test` for integration tests against the live deploy" | Use `skaffold verify` -- it runs test containers after deploy. |
| "I need to restart to pick up skaffold.yaml changes" | `skaffold dev` watches `skaffold.yaml` and restarts automatically. |
