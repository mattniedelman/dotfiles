---
type: agent_requested
description: CI/CD patterns using GitHub Actions, GitOps with ArgoCD, deployment strategies, pipeline design, and automation best practices
---

# CI/CD Patterns with GitHub Actions and ArgoCD

## GitHub Actions Workflow Structure

**Standard Workflow Organization:**
```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
          cache: 'pip'
      
      - name: Install dependencies
        run: |
          pip install uv
          uv sync
      
      - name: Run tests
        run: uv run pytest --cov --cov-report=xml
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.xml

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      
      - name: Run linting
        run: |
          pip install ruff
          ruff check .
          ruff format --check .

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run security scan
        run: |
          pip install pip-audit
          pip-audit
```

## Pipeline Design Principles

**Separate Concerns:**
- **CI Pipeline**: Build, test, lint, security scan
- **CD Pipeline**: Deploy to environments
- **Release Pipeline**: Tag, changelog, artifacts

**Fast Feedback:**
- Run fast tests first (unit tests)
- Run slow tests later (integration, e2e)
- Fail fast on critical issues
- Parallelize independent jobs

**Example Multi-Stage Pipeline:**
```yaml
jobs:
  # Stage 1: Fast checks (< 2 minutes)
  quick-checks:
    runs-on: ubuntu-latest
    steps:
      - name: Lint
      - name: Type check
      - name: Unit tests

  # Stage 2: Comprehensive tests (< 10 minutes)
  integration-tests:
    needs: quick-checks
    runs-on: ubuntu-latest
    steps:
      - name: Integration tests
      - name: API tests

  # Stage 3: Build and publish (only on main)
  build:
    needs: integration-tests
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Build Docker image
      - name: Push to registry
```

## Docker Image Building

**Multi-Stage Dockerfile:**
```dockerfile
# Build stage
FROM python:3.11-slim as builder
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN pip install uv && uv sync --frozen

# Runtime stage
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
COPY . .
ENV PATH="/app/.venv/bin:$PATH"
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0"]
```

**GitHub Actions Docker Build:**
```yaml
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3

- name: Login to Container Registry
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}

- name: Build and push
  uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    tags: |
      ghcr.io/${{ github.repository }}:${{ github.sha }}
      ghcr.io/${{ github.repository }}:latest
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

## GitOps with ArgoCD

**Repository Structure:**
```
infrastructure/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
├── overlays/
│   ├── dev/
│   │   ├── kustomization.yaml
│   │   └── patches.yaml
│   ├── staging/
│   │   ├── kustomization.yaml
│   │   └── patches.yaml
│   └── production/
│       ├── kustomization.yaml
│       └── patches.yaml
```

**Base Deployment:**
```yaml
# infrastructure/base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: ghcr.io/org/myapp:latest
        ports:
        - containerPort: 8000
        env:
        - name: ENVIRONMENT
          value: production
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

**Environment Overlay:**
```yaml
# infrastructure/overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

replicas:
  - name: myapp
    count: 5

images:
  - name: ghcr.io/org/myapp
    newTag: v1.2.3

patches:
  - path: patches.yaml
```

## ArgoCD Application Configuration

**ArgoCD Application Manifest:**
```yaml
# argocd/applications/myapp-production.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp-production
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/org/infrastructure
    targetRevision: main
    path: overlays/production

  destination:
    server: https://kubernetes.default.svc
    namespace: production

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

**Sync Strategies:**
- **Automated Sync**: ArgoCD automatically syncs when Git changes
- **Manual Sync**: Require manual approval for production
- **Sync Waves**: Control deployment order with annotations
- **Hooks**: Pre/post sync hooks for migrations, tests

## Image Update Workflow

**Automated Image Updates:**
```yaml
# .github/workflows/update-image.yml
name: Update Image Tag

on:
  workflow_run:
    workflows: ["CI"]
    types: [completed]
    branches: [main]

jobs:
  update-manifest:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout infrastructure repo
        uses: actions/checkout@v4
        with:
          repository: org/infrastructure
          token: ${{ secrets.INFRA_PAT }}

      - name: Update image tag
        run: |
          cd overlays/staging
          kustomize edit set image \
            ghcr.io/org/myapp:${{ github.sha }}

      - name: Commit and push
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add .
          git commit -m "chore: update myapp image to ${{ github.sha }}"
          git push
```

## Deployment Strategies

**Blue-Green Deployment:**
```yaml
# Use ArgoCD Rollouts for advanced strategies
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: myapp
spec:
  replicas: 5
  strategy:
    blueGreen:
      activeService: myapp-active
      previewService: myapp-preview
      autoPromotionEnabled: false
      scaleDownDelaySeconds: 30
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: ghcr.io/org/myapp:latest
```

**Canary Deployment:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: myapp
spec:
  replicas: 5
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {duration: 5m}
      - setWeight: 40
      - pause: {duration: 5m}
      - setWeight: 60
      - pause: {duration: 5m}
      - setWeight: 80
      - pause: {duration: 5m}
```

## Secrets Management

**Sealed Secrets:**
```yaml
# Encrypt secrets for Git storage
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: myapp-secrets
  namespace: production
spec:
  encryptedData:
    database-url: AgBx7f9... # Encrypted value
```

**External Secrets Operator:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: myapp-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: myapp-secrets
  data:
  - secretKey: database-url
    remoteRef:
      key: production/myapp/database-url
```

## Environment Promotion

**Promotion Workflow:**
1. **Development**: Auto-deploy from `develop` branch
2. **Staging**: Auto-deploy from `main` branch
3. **Production**: Manual approval + tag-based deployment

**GitHub Actions Promotion:**
```yaml
name: Promote to Production

on:
  release:
    types: [published]

jobs:
  promote:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout infrastructure
        uses: actions/checkout@v4
        with:
          repository: org/infrastructure
          token: ${{ secrets.INFRA_PAT }}

      - name: Update production image
        run: |
          cd overlays/production
          kustomize edit set image \
            ghcr.io/org/myapp:${{ github.event.release.tag_name }}

      - name: Create PR
        uses: peter-evans/create-pull-request@v5
        with:
          title: "chore: promote myapp to ${{ github.event.release.tag_name }}"
          body: "Automated promotion from release"
          branch: promote-${{ github.event.release.tag_name }}
```

## Monitoring and Rollback

**Health Checks:**
```yaml
# Add health checks to deployments
livenessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8000
  initialDelaySeconds: 5
  periodSeconds: 5
```

**Automatic Rollback:**
```yaml
# ArgoCD Rollout with automatic rollback
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  strategy:
    canary:
      analysis:
        templates:
        - templateName: success-rate
        startingStep: 2
      steps:
      - setWeight: 20
      - pause: {duration: 5m}
      - analysis:
          templates:
          - templateName: success-rate
```

## CI/CD Best Practices

**Pipeline Optimization:**
- Cache dependencies (pip, npm, Docker layers)
- Use matrix builds for multiple versions/platforms
- Parallelize independent jobs
- Use self-hosted runners for faster builds

**Security:**
- Scan Docker images for vulnerabilities
- Use least-privilege service accounts
- Rotate secrets regularly
- Audit pipeline access and changes

**Observability:**
- Track deployment frequency and lead time
- Monitor deployment success rate
- Alert on failed deployments
- Track rollback frequency

**GitOps Principles:**
- Git as single source of truth
- Declarative configuration
- Automated synchronization
- Continuous reconciliation
- Audit trail via Git history


