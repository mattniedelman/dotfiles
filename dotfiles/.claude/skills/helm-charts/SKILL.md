---
name: helm-charts
description: Use when authoring, editing, or reviewing a Helm chart (Helm 3) - writing Chart.yaml, values.yaml, templates, _helpers.tpl, or packaging a chart for distribution. Triggers on any request to create a chart, templatize Kubernetes manifests into a chart, add resources to an existing chart, or fix chart rendering/upgrade problems.
when_to_use: Creating a new Helm chart; converting raw Kubernetes YAML into a chart; adding a Deployment/Service/Ingress/HPA/ConfigMap/Secret template; writing or fixing named templates and label helpers; debugging "selector immutable" upgrade rejections, values that render as scientific notation, secrets regenerating on upgrade, or namespace conflicts; packaging, versioning, signing, or publishing a chart to an HTTP or OCI registry.
---

# Authoring Helm Charts (Helm 3)

## Overview

This is a reference skill for writing correct, maintainable Helm 3 charts. Most
chart scaffolding is mechanical - `helm create` gets you 80% there. The value of
this skill is the 20% that bites later: the gotchas that pass `helm lint`, render
fine, install successfully, and then fail on upgrade or silently produce wrong
output.

**Start from the scaffold, then harden.** Run `helm create <name>` and edit it.
Do not hand-write the boilerplate from memory - the scaffold's `_helpers.tpl`,
label structure, and 63-char truncation are correct and version-current. When
you cannot run `helm create` (reviewing, converting raw YAML, no helm on PATH),
copy from the hardened worked chart in `examples/webapp/` - it lints, renders,
and validates against real Kubernetes schemas, and every file bakes in a
gotcha-avoidance below.

**Verify before declaring done.** A chart is not finished until it passes:

```bash
helm lint <chart> --strict
helm template <chart> | kubeconform -strict -    # or kubeval is UNMAINTAINED - use kubeconform
helm template <chart> -f values-prod.yaml        # render every environment you ship
```

`helm lint` passing is necessary, not sufficient. Most gotchas below render clean.

## Gotchas that bite (read this section every time)

These pass lint and render. They fail later. This is the core of the skill.

| Trap | What happens | Fix |
|------|-------------|-----|
| **`version` in selector labels** | `Deployment.spec.selector.matchLabels` is **immutable** in `apps/v1`. Put `app.kubernetes.io/version` (or anything that changes on upgrade) in the selector and `helm upgrade` is **rejected by the API server**. | Selector labels = stable subset only (`name` + `instance`). Keep `version`/`chart` in the full `labels` block, never in `selectorLabels`. The scaffold splits these for exactly this reason - preserve the split. |
| **`default` on a boolean** | `{{ .Values.enabled \| default true }}` coerces an explicit `false` to `true` - Sprig counts boolean `false` as empty. The user sets `enabled: false`, the chart enables it anyway. | Branch on presence: `{{- if hasKey .Values "enabled" }}` or `{{- if kindIs "bool" .Values.enabled }}`. Never use `default` to supply a boolean fallback. |
| **Large integers -> scientific notation** | An unquoted large number (e.g. a `1000000` timeout, a phone number, an ID) can serialize as `1e+06` and reach the cluster as garbage. | Quote large numeric literals that are _not_ used in template arithmetic: `"1000000"`. Same for any value that must stay a string (zip codes, account IDs). |
| **`randAlphaNum` for secrets/checksums** | Regenerates on **every** `helm upgrade`. As a secret value it clobbers the live password; as a pod annotation it forces a spurious restart every upgrade. | For secrets, use the `lookup` pattern - preserve existing, generate only on first install (exact pattern in `reference.md`; reconstructing the double-b64 from memory is error-prone). For roll-on-change, use the `checksum/config` sha256sum pattern (`reference.md`), never random. |
| **Hardcoded `metadata.namespace`** | Pins the resource to one namespace, breaks multi-env installs, and fights `--namespace`/`--create-namespace`. | Never set `metadata.namespace` in templates. Use `.Release.Namespace` only where a value is genuinely needed (e.g. building a FQDN). Namespaces are an operator concern, not a chart concern. |
| **`template` instead of `include`** | `{{ template "x" . }}` is an action - its output **cannot be piped**, so you cannot indent it. Block YAML ends up at column 0 and breaks. | Always `{{ include "x" . \| nindent N }}`. `include` is a function and pipes. This is the single most important templating idiom. |
| **`toYaml` with bare `indent`** | `indent` indents every line but adds no leading newline, so the first line collides with the key. | Pair `toYaml` with `nindent` (newline + indent): `{{- toYaml .Values.resources \| nindent 12 }}`. |
| **`.` rebinding in `range`/`with`** | Inside `range`/`with`, `.` is the loop/block scope - `.Release`, `.Values` are unreachable. `with` also skips the whole block if the value is empty. | Use `$` for root (`$.Release.Name`) or capture before entering (`{{- $root := . }}`). |
| **Hardcoded API versions** | Chart breaks on clusters where the API graduated/removed a version. | Gate with `{{- if .Capabilities.APIVersions.Has "autoscaling/v2" }}`. |
| **Floating image tags** | `:latest` makes `imagePullPolicy` default to `Always` and makes rollouts non-reproducible. | Pin tags; default `image.tag` to `""` and fall back to `.Chart.AppVersion`. |

## Chart.yaml essentials

- `apiVersion: v2` (Helm 3 - enables inline `dependencies:` and `type:`).
- `version` is the **chart** version: strict SemVer 2. Bump MAJOR for breaking
  chart changes (new required values, removed resources), MINOR for compatible
  additions, PATCH for fixes.
- `appVersion` is the **app** version: informational, not SemVer-constrained,
  moves independently. **Quote it** - unquoted `1.0` mis-types to a float
  (`helm create` auto-quotes since v3.5.0).
- `type: application` (default) or `library` (helpers only, renders nothing,
  not installable standalone).
- Declare dependencies inline (`dependencies:`), not in a `requirements.yaml`
  (Helm 2 legacy). Commit `Chart.lock` for reproducible builds. Use `condition`
  (a boolean values path) to toggle one subchart, `tags` to toggle groups;
  condition wins when both are set.

## values.yaml conventions

- camelCase keys, starting lowercase.
- Prefer **flat over deeply nested** (fewer existence checks, easier `--set`);
  prefer **maps over arrays** (`servers.nginx.port` survives reordering;
  `servers[0]` does not).
- Provide sensible defaults so the chart installs out of the box. Use an empty
  default (`apiKey:`) where the user must supply a value but the key should exist
  for `--set`/schema.
- Quote ambiguous strings: `enabled: "false"` (string) vs `enabled: false` (bool).
- Document every value with a `# -- description` comment above the key
  (helm-docs format) and consider a `values.schema.json` to validate types,
  required keys, and enums on lint/install.

## Templates and helpers

- Named templates are **global** across the chart and all subcharts - last
  definition wins. **Always prefix with the chart name** (`mychart.labels`,
  `mychart.fullname`) to avoid collisions.
- Use the recommended Kubernetes labels: `app.kubernetes.io/name`,
  `app.kubernetes.io/instance`, `app.kubernetes.io/managed-by`,
  `app.kubernetes.io/version`, `helm.sh/chart`. The scaffold's `labels` and
  `selectorLabels` helpers produce these correctly - reuse them everywhere.
- `default D V` for empty fallbacks (but NOT booleans - see gotchas).
  `required "msg" V` to hard-fail rendering when a value is missing.
  `tpl STRING .` to render a values string as a template.
- `trunc 63 | trimSuffix "-"` on every generated name (DNS-1123 limit).

See `reference.md` for the canonical `_helpers.tpl` (byte-exact from `helm create`),
the `checksum/config` and `lookup`-secret patterns, hooks, testing tools, and
distribution (HTTP/OCI/signing).

## Resource hardening checklist

For a production workload template, confirm:

- [ ] Resource **requests** set (limits per org policy; CPU limits are debatable
      for latency-sensitive apps due to CFS throttling - decide deliberately).
- [ ] Liveness + readiness probes (startup probe if slow boot), configurable.
- [ ] `securityContext`: `runAsNonRoot: true`, `allowPrivilegeEscalation: false`,
      `readOnlyRootFilesystem: true`, `capabilities.drop: [ALL]`,
      `seccompProfile: RuntimeDefault`. Add a writable `emptyDir` for `/tmp` if
      the root FS is read-only.
- [ ] `checksum/config` annotation on the pod template so ConfigMap/Secret
      changes trigger a rolling update.
- [ ] Dedicated ServiceAccount; `automountServiceAccountToken: false` unless the
      app calls the K8s API.
- [ ] When an HPA is enabled, **omit `replicas`** from the Deployment so the HPA
      owns the count (otherwise they fight on every sync).
- [ ] **No secrets in values.yaml or templates.** K8s Secrets are base64-encoded,
      not encrypted - `b64enc` gives zero confidentiality. Reference an existing
      externally-managed secret (External Secrets Operator, Vault, Sealed
      Secrets, SOPS) by default; make chart-rendered secrets opt-in only.

## Red flags - stop and check the gotchas table

If you catch yourself doing any of these, you are about to ship a latent bug:

- Adding `version` (or any mutable label) to a selector
- Writing `| default true` / `| default false` for a boolean value
- Reaching for `randAlphaNum` to fill a secret or annotation
- Typing `metadata.namespace:` in a template
- Writing `{{ template ... }}` where output needs indentation
- Hardcoding an `apiVersion` for a resource that has multiple across K8s versions
- Leaving a large integer unquoted in values.yaml
