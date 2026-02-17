---
type: always_apply
priority: HIGH
description: Helm chart and Kubernetes manifest guidelines with namespace policy enforcement
last_updated: 2025-01-27
---

# Helm and Kubernetes Guidelines

## ⚠️ CRITICAL: Helm Chart Namespace Management Rule ⚠️

**ABSOLUTE RULE**:
Helm charts in this project must NEVER manage namespaces directly.

### Prohibited Actions

1. **DO NOT create Namespace resources** within Helm charts
   - No `kind:
     Namespace` manifests in any chart template
   - Namespaces are infrastructure concerns, not application concerns

2. **DO NOT include `namespace` as a configurable value**
   - No `namespace` field in `values.yaml`
   - No namespace configuration options exposed to users

3. **DO NOT hardcode namespace values**
   - No hardcoded namespace strings in chart templates
   - Avoid any static namespace references

4. **DO NOT allow users to specify namespace through chart values**
   - Namespace selection is a deployment-time decision
   - Not a chart configuration concern

### Required Approach

**Namespace MUST be specified at installation time:**

```bash
# Correct approach - namespace specified at install/upgrade time
helm install my-release ./my-chart --namespace my-namespace --create-namespace
helm upgrade my-release ./my-chart --namespace my-namespace
```

**The namespace is managed externally to the chart, not by the chart itself.**

### When Namespace Reference is Necessary

In rare cases where you must reference the namespace (e.g., in RoleBinding
subjects, ClusterRoleBinding, or cross-namespace references):

**✅ CORRECT - Use the built-in Helm template variable:**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ include "mychart.fullname" . }}
subjects:
- kind: ServiceAccount
  name: {{ include "mychart.serviceAccountName" . }}
  namespace: {{ .Release.Namespace }}
```

**❌ INCORRECT - Hardcoded or values-based namespace:**

```yaml
# DON'T DO THIS
subjects:
- kind: ServiceAccount
  name: my-service-account
  namespace: my-hardcoded-namespace  # ❌ Hardcoded

# DON'T DO THIS EITHER
subjects:
- kind: ServiceAccount
  name: my-service-account
  namespace: {{ .Values.namespace }}  # ❌ From values
```

**However, prefer omitting explicit namespace references entirely when
possible**, as Kubernetes will default to the release namespace for namespaced
resources.

### Rationale

1. **Separation of Concerns**:
   Namespace lifecycle should be managed independently from application
   deployment
2. **Prevents Conflicts**:
   Avoids namespace ownership conflicts and allows multiple releases in
   different namespaces
3. **Multi-tenancy Support**:
   Enables better isolation and reusability across environments
4. **Helm Best Practices**:
   Follows official Helm recommendations for chart portability
5. **Flexibility**:
   Allows the same chart to be deployed to any namespace without modification

### Enforcement

- **Code Review**:
  All Helm chart changes must be reviewed for namespace management violations
- **Testing**:
  Chart installation tests must verify namespace is not managed by the chart
- **CI/CD**:
  Automated checks should flag any `kind:
  Namespace` resources in charts

## Helm Chart Best Practices

### Chart Structure

- **Rule**:
  Follow standard Helm chart directory structure
- **Implementation**:
  - `Chart.yaml` - Chart metadata and dependencies
  - `values.yaml` - Default configuration values
  - `templates/` - Kubernetes manifest templates
  - `templates/_helpers.tpl` - Template helpers and named templates
  - `templates/NOTES.txt` - Post-installation notes

### Values Organization

- **Rule**:
  Organize values.yaml hierarchically and document all options
- **Implementation**:
  - Group related configuration together
  - Provide sensible defaults for all values
  - Document each value with inline comments
  - Use consistent naming conventions (camelCase or snake_case, but be
    consistent)

### Template Helpers

- **Rule**:
  Use named templates for repeated logic
- **Implementation**:
  - Define common labels in `_helpers.tpl`
  - Create reusable template functions for names, labels, selectors
  - Follow naming convention:
    `<chart-name>.<helper-name>`

### Resource Naming

- **Rule**:
  Use consistent, predictable resource names
- **Implementation**:
  - Use `{{ include "mychart.fullname" .
    }}` for resource names
  - Include release name in resource names for uniqueness
  - Avoid hardcoded resource names

### Labels and Selectors

- **Rule**:
  Apply consistent labels to all resources
- **Implementation**:
  - Use recommended Kubernetes labels (app.kubernetes.io/*)
  - Include chart name, version, instance, and managed-by labels
  - Ensure selector labels are immutable and consistent

## Kubernetes Resource Guidelines

### Resource Limits and Requests

- **Rule**:
  Always define resource limits and requests for containers
- **Implementation**:
  - Set both CPU and memory limits
  - Set both CPU and memory requests
  - Make limits configurable via values.yaml
  - Provide reasonable defaults based on application requirements

### Health Checks

- **Rule**:
  Implement liveness and readiness probes for all deployments
- **Implementation**:
  - Define appropriate probe endpoints
  - Configure reasonable timeout and period values
  - Make probe configuration customizable
  - Use different endpoints for liveness vs readiness when appropriate

### Security Context

- **Rule**:
  Apply security best practices to all workloads
- **Implementation**:
  - Run containers as non-root user when possible
  - Set read-only root filesystem where applicable
  - Drop unnecessary capabilities
  - Use security context at both pod and container level

### ConfigMaps and Secrets

- **Rule**:
  Externalize configuration using ConfigMaps and Secrets
- **Implementation**:
  - Never hardcode sensitive data in templates
  - Use Secrets for sensitive information
  - Use ConfigMaps for non-sensitive configuration
  - Support external secret management systems (e.g., External Secrets Operator)
