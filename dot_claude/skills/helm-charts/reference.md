# Helm Chart Authoring - Reference

Lookup material for the `helm-charts` skill. Consult on demand; do not preload.

> Maintenance note: if this file grows past ~4k tokens, split it by axis
> (templating / patterns / distribution). Until then one file is correct.

## Worked example chart

A complete, hardened reference chart lives in `examples/webapp/` next to this
file. It lints `--strict`, renders for default and production values, and every
manifest validates against real Kubernetes schemas with `kubeconform`. Read it
when authoring from scratch, converting raw YAML, or reviewing a chart you
cannot run `helm create` against. Each file demonstrates a gotcha-avoidance:

| File | Demonstrates |
|------|-------------|
| `templates/_helpers.tpl` | name/label helpers; `selectorLabels` as the immutable stable subset |
| `templates/deployment.yaml` | `include \| nindent`, `checksum/config`, HPA-omits-`replicas`, hardened securityContext, named-port probes, read-only root FS + `/tmp` emptyDir |
| `templates/hpa.yaml` | `.Capabilities.APIVersions.Has` version gating |
| `templates/secret.yaml` | chart-managed secret as strict opt-in; default is `existingSecret` |
| `templates/configmap.yaml` | `quote` on values so large ints do not become scientific notation |
| `values.yaml` | documented contract, camelCase, sane defaults, quoted large int |
| `values.schema.json` | type/enum/range validation of values |
| `values-prod.yaml` | per-environment overrides (autoscaling, PDB, ingress, external secret) |

The byte-exact `_helpers.tpl` below is the same content for quick reference; the
chart in `examples/` is the runnable, verified copy.

## Canonical _helpers.tpl (from `helm create`, Helm v3.21)

Generate fresh with `helm create demo && cat demo/templates/_helpers.tpl` -
helpers drift across minor versions. Replace `demo` with the chart name. The
key structural points: `fullname` truncates to 63 chars, `chart` replaces `+`
with `_` (illegal in label values), and `selectorLabels` is a strict subset of
`labels` (no `version`).

```gotemplate
{{/* Expand the name of the chart. */}}
{{- define "demo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Create a default fully qualified app name. Truncate at 63 chars (DNS spec).
     If release name contains chart name it is used as the full name. */}}
{{- define "demo.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/* Chart name and version, for the chart label. */}}
{{- define "demo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Common labels */}}
{{- define "demo.labels" -}}
helm.sh/chart: {{ include "demo.chart" . }}
{{ include "demo.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Selector labels - STABLE SUBSET ONLY. Never add version here. */}}
{{- define "demo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "demo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* Name of the service account to use */}}
{{- define "demo.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "demo.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
```

## checksum/config - roll pods when ConfigMap/Secret changes

On the Deployment pod template metadata:

```gotemplate
spec:
  template:
    metadata:
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
        checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
```

Changing the rendered ConfigMap/Secret changes the hash -> pod template changes
-> rolling update. Never use `randAlphaNum` here - it changes every render and
forces a restart on every upgrade.

## lookup pattern - preserve a generated secret across upgrades

`randAlphaNum` alone regenerates the password on every upgrade. Use `lookup` to
read the existing secret and only generate on first install:

```gotemplate
{{- $name := include "demo.fullname" . }}
{{- $existing := (lookup "v1" "Secret" .Release.Namespace $name) }}
{{- $password := "" }}
{{- if $existing }}
{{-   $password = index $existing.data "password" }}      {{/* already b64 */}}
{{- else }}
{{-   $password = randAlphaNum 32 | b64enc }}
{{- end }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ $name }}
data:
  password: {{ $password }}
```

`lookup` returns empty under `helm template` and `--dry-run=client` (no cluster
contact) - it only works against a live API server. Prefer an externally-managed
secret (ESO/Vault/Sealed Secrets/SOPS) over chart-generated secrets where you can.

## nil vs empty vs missing

| Function | Tests | Notes |
|----------|-------|-------|
| `hasKey .Values "k"` | key **presence** | true even when value is `""`/`0`/`false` |
| `empty V` | **falsiness** | true for `""`, `0`, `false`, `nil`, empty coll |
| `kindIs "bool" V` | runtime type | use to distinguish a real bool from absent |
| `dig "a" "b" def .Values` | nested walk | safe deep access without per-level `if` |

This is why `default` is wrong for booleans: `default` calls `empty`, and `empty
false == true`, so an explicit `false` gets the fallback.

## Built-in objects quick reference

- `.Release` - `.Name`, `.Namespace`, `.IsInstall`, `.IsUpgrade`, `.Revision`,
  `.Service` (always `"Helm"`).
- `.Chart` - mirrors Chart.yaml: `.Name`, `.Version`, `.AppVersion`.
- `.Values` - merged user values.
- `.Capabilities` - `.APIVersions.Has "autoscaling/v2"` (API gating),
  `.KubeVersion`, `.HelmVersion`.
- `.Files` - `.Get`, `.GetBytes`, `.Glob`, `.Lines`, `.AsConfig`, `.AsSecrets`
  (cannot read anything under `templates/`).
- `.Template` - `.Name`, `.BasePath` (used in the checksum pattern).

## Hooks

Annotations on a resource turn it into a hook:

```yaml
metadata:
  annotations:
    "helm.sh/hook": pre-upgrade,pre-install
    "helm.sh/hook-weight": "5"  # string; ascending order
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
```

- Events: `pre/post-install`, `pre/post-upgrade`, `pre/post-rollback`,
  `pre/post-delete`, `test`.
- Hooks are **not tracked as part of the release** - `helm uninstall` will not
  clean them up. Set a delete policy or a Job TTL.
- Use for migrations (`pre-upgrade`), validation, cleanup (`post-delete`). Do not
  route normal app lifecycle through hooks.

## CRDs

- Files in `crds/` are **plain YAML, not templated**, installed before templates.
- Helm **does not upgrade or delete** CRDs (data-loss guard) - existing CRDs are
  skipped with a warning. Ship CRD upgrades as a separate process/chart.
- CRDs don't register under `--dry-run`, so a chart that both defines and
  consumes a CRD can fail dry-run. Split them.

## Testing and quality tools

| Tool | Use | Note |
|------|-----|------|
| `helm lint --strict` | offline structural check | `--strict` promotes warnings to errors (CI) |
| `helm template` | offline render to stdout | `--api-versions` fakes Capabilities; `--show-only` for one file |
| `--dry-run=client` | offline | like `helm template`; `lookup` returns empty |
| `--dry-run=server` | contacts cluster | real CRDs, admission, Capabilities |
| `helm test <release>` | run test hooks | workloads in `templates/tests/`, annotated `helm.sh/hook: test` |
| `kubeconform` | schema-validate rendered YAML | `helm template . \| kubeconform -strict -`. **kubeval is unmaintained** |
| `ct` (chart-testing) | CI lint+install on kind | enforces a chart `version` bump by default |
| `helm-unittest` | offline YAML unit tests | `tests/*_test.yaml`, snapshot support with `-u` |
| `helm-docs` | generate README from value comments | `# -- desc` above each key |
| `values.schema.json` | validate values on lint/install | type/required/enum/pattern/min-max |

## Distribution

- **Versioning:** chart `version` is strict SemVer 2; `appVersion` moves
  independently. `ct` gates the bump in CI.
- **HTTP repos:** `helm package`, `helm repo index --merge` -> `index.yaml`
  served over HTTP (ChartMuseum / Artifactory / GH Pages).
- **OCI registries** (GA in Helm 3.8+): `helm registry login HOST`,
  `helm push chart-VER.tgz oci://HOST/repo`,
  `helm install rel oci://HOST/repo/chart --version X`. Supports digest pinning
  (`...@sha256:...`); `repository: oci://...` works in `dependencies`.
- **Signing:** `helm package --sign` produces a `.tgz.prov` (PGP);
  `helm verify` / `helm install --verify` aborts on mismatch. For OCI,
  Cosign/Sigstore keyless (OIDC) signing is increasingly preferred.

## Dependencies detail

```yaml
dependencies:
  - name: postgresql
    version: "~11.2.0"  # tilde range >=11.2.0,<11.3.0
    repository: "https://charts.example.com"  # or oci:// or file://
    condition: postgresql.enabled  # boolean values path; condition wins over tags
    tags: [database]
    alias: postgres  # install same chart under another name
```

- `helm dependency update` resolves deps into `charts/` and writes `Chart.lock`;
  `helm dependency build` rebuilds from the lock. Commit `Chart.lock`.
- Standard version ranges exclude pre-releases; append `-0` (`~1.2.3-0`) to
  include them.

## Upgrade & rollback mechanics (footgun class)

Helm 3 upgrades use a **three-way strategic merge**: it diffs the old manifest,
the new manifest, and the **live cluster state**. Consequences that surprise
people:

- **Removing a field from a template does not always remove it from the live
  object.** If something else (a controller, a `kubectl edit`) set it, the
  three-way merge can preserve it. Removing a whole resource from the chart
  _does_ delete it on upgrade.
- **`helm rollback REL N`** rolls back to a stored revision (`helm history REL`).
  Failed upgrades are still revisions; rollback targets the last good one.
- **`--atomic`** rolls back automatically if the upgrade fails; **`--wait`**
  blocks until resources are ready (implied by `--atomic`). Use both in CI.
- **`--force`** deletes and recreates resources on conflict -- it causes
  downtime and can fail on immutable fields. Avoid unless you know why you need
  it.
- **`--cleanup-on-fail`** removes resources created during a failed upgrade.
- The **`helm diff` plugin** (`helm diff upgrade REL chart -f vals.yaml`) shows
  the rendered delta before applying. Strongly recommended in review/CD.
- A common upgrade rejection is the **immutable selector** (see SKILL.md gotcha):
  the API server refuses `spec.selector` changes on Deployments/StatefulSets.

## Capability & version gating recipes

Gate on the API the cluster actually serves, never hardcode:

```gotemplate
{{- if .Capabilities.APIVersions.Has "autoscaling/v2" }}
apiVersion: autoscaling/v2
{{- else }}
apiVersion: autoscaling/v2beta2
{{- end }}
```

| Resource | Stable apiVersion | Older fallback |
|----------|-------------------|----------------|
| HPA | `autoscaling/v2` (>=1.23) | `autoscaling/v2beta2` |
| Ingress | `networking.k8s.io/v1` (>=1.19) | `networking.k8s.io/v1beta1` |
| PodDisruptionBudget | `policy/v1` (>=1.21) | `policy/v1beta1` |
| CronJob | `batch/v1` (>=1.21) | `batch/v1beta1` |

`helm template --api-versions autoscaling/v2` fakes the capability set for
offline rendering. Use `.Capabilities.KubeVersion.Minor` only as a last resort
(it is a string and needs `semverCompare`).

## Debugging a chart

| Command | Shows |
|---------|-------|
| `helm install REL chart --dry-run --debug` | rendered manifests + `COMPUTED VALUES` (merged values, including `tpl` results) |
| `helm template chart --show-only templates/deployment.yaml` | a single rendered file |
| `helm get manifest REL` | what is actually applied for a live release |
| `helm get values REL [-a]` | user-supplied (`-a`: all computed) values for a release |
| `helm get hooks REL` | rendered hook resources |
| `helm history REL` | revision list for rollback |

When a template errors, `--debug` prints the partially rendered output and the
line. `printf "%#v"` / the `toYaml` of a value mid-template is the fastest way to
inspect scope confusion (`.` vs `$`).

## Subcharts & global values

- A parent's `values.yaml` overrides a subchart's values under a key matching
  the subchart name (or its `alias`): `postgresql: { auth: { username: app } }`.
- **`global`** is a reserved top-level values key propagated to **all**
  subcharts: `global.imageRegistry`, `global.storageClass`. Subcharts read it as
  `.Values.global.*`. Use it for cross-cutting settings only.
- **Parent overrides child**; a subchart cannot override its parent.
- **`import-values`** (in a dependency entry) maps a child's exported values up
  into the parent, via explicit `child`/`parent` pairs or a child `exports:`
  block.
- Named templates are global -- a subchart can `include` a parent helper and vice
  versa, which is why chart-name prefixing matters (see SKILL.md).
