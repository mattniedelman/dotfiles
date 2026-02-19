# Helm & Kubernetes Best Practices

Use when creating or modifying Helm charts or Kubernetes manifests.

**CRITICAL**:
See `helm-kubernetes-guidelines.md` rule for namespace policy (never manage
namespaces in charts).

## Chart Structure

```text
my-chart/
├── Chart.yaml          # Metadata and dependencies
├── values.yaml         # Default configuration
├── templates/
│   ├── _helpers.tpl    # Named templates
│   ├── deployment.yaml
│   ├── service.yaml
│   └── NOTES.txt       # Post-install notes
```

## Values Organization

- Group related config hierarchically
- Provide sensible defaults for all values
- Document each value with inline comments
- Use consistent naming (camelCase or snake_case, be consistent)

```yaml
# values.yaml
replicaCount: 1

image:
  repository: myapp
  tag: latest
  pullPolicy: IfNotPresent

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi
```

## Template Helpers (_helpers.tpl)

Define reusable templates for names, labels, selectors:

```yaml
{{- define "mychart.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "mychart.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end }}

{{- define "mychart.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

## Resource Naming

- Use `{{ include "mychart.fullname" .
  }}` for resource names
- Include release name for uniqueness
- Avoid hardcoded names

## Labels and Selectors

Apply recommended Kubernetes labels to all resources:

```yaml
metadata:
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "mychart.selectorLabels" . | nindent 6 }}
```

## Resource Limits and Requests

Always define both limits and requests:

```yaml
resources:
  {{- toYaml .Values.resources | nindent 12 }}
```

Make configurable via values.yaml with reasonable defaults.

## Health Checks

Implement liveness and readiness probes:

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: http
  initialDelaySeconds: 10
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /ready
    port: http
  initialDelaySeconds: 5
  periodSeconds: 5
```

Use different endpoints when appropriate (readiness for dependencies, liveness
for stuck processes).

## Security Context

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

## ConfigMaps and Secrets

- Never hardcode sensitive data
- Use Secrets for sensitive info, ConfigMaps for non-sensitive
- Support external secret management (External Secrets Operator)

```yaml
env:
  - name: CONFIG_VALUE
    valueFrom:
      configMapKeyRef:
        name: {{ include "mychart.fullname" . }}
        key: config-value
  - name: SECRET_VALUE
    valueFrom:
      secretKeyRef:
        name: {{ include "mychart.fullname" . }}
        key: secret-value
```

## Namespace Reference (When Required)

Only use `{{ .Release.Namespace }}` when absolutely necessary (e.g.,
ClusterRoleBinding subjects).
Prefer omitting namespace - Kubernetes defaults to release namespace.
