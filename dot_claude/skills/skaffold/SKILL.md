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
| Use `apiVersion: skaffold/v4beta6` | Current schema is `skaffold/v4beta13`. Use `skaffold fix` to migrate. |
| Set `concurrency: 3` for parallel builds | `build-concurrency: 0` = unlimited parallel. `-1` (default) = sequential per dependency order. |
| Hardcode full registry path in artifact image names | Use `default-repo` to keep image names short; Skaffold prepends the registry. |
| GCR (`gcr.io`) is the standard GKE registry | Artifact Registry (`REGION-docker.pkg.dev`) is the modern choice; GCR is legacy. |
| File sync speeds up `skaffold run` | File sync only works with `skaffold dev`, not `skaffold run` or `skaffold debug`. |
| Profile kube-context activation uses glob regex | Use `kubeContext` in activation -- supports glob-style patterns, not full regex. |
| `portForwards` is the YAML key | The key is `portForward` (singular). |
| `skaffold dev` is the starting point | Run `skaffold diagnose` first when config looks wrong. |
| Tagging is automatic and always works | Default tagger is `gitCommit`. In CI environments without git history, configure `envTemplate` or `sha256` explicitly. |

---

## skaffold.yaml Structure

```yaml
apiVersion: skaffold/v4beta13  # always use the current version
kind: Config
metadata:
  name: my-app

build:
  artifacts: ['...']
  local:
    concurrency: 0  # 0 = all artifacts built in parallel

deploy:
  kubectl: {}  # or helm: / kustomize:

portForward: ['...']  # singular, not portForwards

profiles: ['...']
```

Run `skaffold fix --overwrite` to migrate older configs to the current schema.

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
[strategic merge patch](https://skaffold.dev/docs/environment/profiles/).

```yaml
profiles:
  - name: prod
    activation:
      - kubeContext: gke_*  # glob pattern, not regex
      - env: CI=true  # environment variable
      - command: run  # only for `skaffold run`
    build:
      googleCloudBuild:
        projectId: my-project
```

**Gotcha**:
Profile activation checks are OR'd -- any matching condition activates the
profile.

---

## File Sync (dev only)

File sync pushes file changes directly into running containers, bypassing
rebuild.

```yaml
build:
  artifacts:
    - image: api
      sync:
        infer: ["**/*.py"]  # Skaffold infers dest from COPY instructions
        manual:  # explicit src -> dest mapping
          - src: "src/**/*.js"
            dest: /app/src
```

**Rules:**

- File sync only runs during `skaffold dev`.
  `skaffold run` always does a full rebuild.
- `infer` requires `COPY` instructions in the Dockerfile to determine the
  destination.
- Sync failures fall back to a full rebuild automatically.

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

Port-forward mode for `skaffold dev`/`run` is controlled by `--port-forward`:

- `off` -- disabled (default for `run`)
- `user` -- only resources defined in `portForward` (default for `dev`)
- `services` -- also forwards all Services
- `pods` -- also forwards all container ports

---

## Tag Policy for CI

The default `gitCommit` tagger fails in CI environments without git history
(shallow clones, detached HEAD, etc.).
Configure explicitly:

```yaml
build:
  tagPolicy:
    envTemplate:
      template: "{{.IMAGE_NAME}}:{{.BUILD_ID}}"  # use any env var
    # or: sha256: {}  # always unique, good for CI
```

When tagging issues arise, `skaffold build --dry-run` shows what tags would be
used without building.

---

## Debugging

```bash
# Attach a language-aware debugger (adds debug ports per language runtime)
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
| "v4beta6 is recent enough" | There have been 7 more releases. Always check current version or run `skaffold fix`. |
| "I'll just hardcode `gcr.io/...` in the image name" | Use `default-repo`. Hardcoded paths break portability and make profile switching harder. |
| "File sync will speed up my `skaffold run` in CI" | Sync is dev-only. CI should use `skaffold build` + `skaffold deploy` split. |
| "I need to set the tag policy manually" | Default `gitCommit` works locally. Only change it when CI lacks git history (`envTemplate` or `sha256`). |
| "The profile `kubeContext` takes a regex" | It takes a glob pattern (`gke_*`), not a regex (`gke_.*`). |
| "I need to restart to pick up skaffold.yaml changes" | `skaffold dev` watches `skaffold.yaml` and restarts automatically. |
