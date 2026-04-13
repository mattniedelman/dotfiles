---
name: observability-driven-development
description: Use when scanning observability stack for issues - queries Grafana/Prometheus, creates beads, dispatches parallel Ralph agents to fix in worktrees
---

# Observability-Driven Development

## Overview

Proactively scan observability stack for issues, triage interactively, and
dispatch parallel Ralph workflows to fix them across repositories.

**Workflow:**

```text
SCAN → TRIAGE → FIX (parallel Ralph) → REVIEW (individual push)
```

## Phase 1: Scan

Query Prometheus for each signal type.
Use `prometheus-prod` by default, `prometheus-nonprod` if specified.

### Signal Categories

#### 🔴 Critical - Immediate Action Required

| Signal | PromQL | Notes |
|--------|--------|-------|
| High restarts (7d) | `sum by (namespace, pod) (increase(kube_pod_container_status_restarts_total[7d])) > 10` | Chronic crashers |
| Last terminated error | `kube_pod_container_status_last_terminated_reason{reason!="Completed"}` | Non-graceful terminations |
| Failed K8s jobs | `kube_job_status_failed > 0` | BackoffLimitExceeded etc |
| Pod waiting errors | `kube_pod_container_status_waiting_reason{reason=~"ImagePullBackOff\|ErrImagePull\|CrashLoopBackOff\|CreateContainerConfigError"} == 1` | Stuck pods |
| Failed/Pending pods | `kube_pod_status_phase{phase=~"Pending\|Unknown\|Failed"} == 1` | Non-running pods |

#### 🟠 High - Investigation Needed

| Signal | PromQL | Notes |
|--------|--------|-------|
| Restarts in 24h | `increase(kube_pod_container_status_restarts_total[24h]) > 0` | Recent instability |
| Restarts >5 (7d) | `increase(kube_pod_container_status_restarts_total[7d]) > 5` | Pattern detection |
| Memory pressure | `sum by (namespace, pod) (kube_pod_container_resource_requests{resource="memory"}) / sum by (namespace, pod) (kube_pod_container_resource_limits{resource="memory"}) > 0.95` | Near-limit pods |
| Scrape targets down | `up == 0` | Broken monitoring |
| ArgoCD unhealthy | `argocd_app_info{health_status!="Healthy"}` | App health issues |
| ArgoCD out of sync | `argocd_app_info{sync_status!="Synced"}` | Sync failures |

#### 🟡 Medium - Monitor/Systematic

| Signal | PromQL | Notes |
|--------|--------|-------|
| Memory req == limit | `kube_pod_container_resource_requests{resource="memory"} / kube_pod_container_resource_limits{resource="memory"} == 1` | Anti-pattern |
| CPU throttling | `rate(container_cpu_cfs_throttled_periods_total[5m]) / rate(container_cpu_cfs_periods_total[5m]) > 0.25` | Resource starved |
| Stale cronjobs | `kube_cronjob_status_last_successful_time < (time() - 86400 * 2)` | Jobs not running |
| HPA maxed out | `kube_hpa_status_current_replicas == kube_hpa_spec_max_replicas` | Scaling ceiling |
| Certs expiring | `(certmanager_certificate_expiration_timestamp_seconds - time()) / 86400 < 30` | 30-day warning |

#### Infrastructure Health

| Signal | PromQL | Notes |
|--------|--------|-------|
| Node conditions | `kube_node_status_condition{condition!="Ready", status="true"} == 1` | Node issues |
| PVC not bound | `kube_persistentvolumeclaim_status_phase{phase!="Bound"} == 1` | Storage issues |
| Disk pressure | `node_filesystem_avail_bytes / node_filesystem_size_bytes < 0.15` | Low disk |
| Deployment stuck | `kube_deployment_status_observed_generation != kube_deployment_metadata_generation` | Rollout issues |
| DaemonSet unavailable | `kube_daemonset_status_number_unavailable > 0` | DS health |
| StatefulSet unready | `kube_statefulset_status_replicas_ready < kube_statefulset_status_replicas` | SS health |
| Service no endpoints | `kube_endpoint_address_available == 0` | Broken services |

### Loki Queries (Grafana)

| Signal | LogQL | Notes |
|--------|-------|-------|
| Exit code 137 (OOM) | `{namespace="argo-workflows"} \|~ "exit code 137\|OOMKilled"` | Container OOMs |
| Error logs | `{namespace="<ns>"} \|~ "error\|exception\|failed" !~ "DEBUG"` | App errors |
| ArgoCD helm errors | `{namespace="argocd"} \|~ "missing in charts/"` | Helm dep failures |

### MCP Tools

```python
# Prometheus query
execute_query(
    query="sum by (namespace, pod) (increase(kube_pod_container_status_restarts_total[7d])) > 10"
)

# Loki logs (Grafana MCP) - use prod datasource UID
query_loki_logs(
    datasourceUid="cdu13x568whdsd",  # prod Loki
    logql='{namespace="argo-workflows"} |~ `exit code 137|OOMKilled`',
    limit=30,
)

# Get firing alerts
get_alert_rules_by_state(state="firing")
```

### Query Execution Order

1. **Critical signals first** - restarts, terminations, failed jobs
2. **Check firing alerts** - Grafana alert rules
3. **Resource pressure** - memory, CPU throttling
4. **Infrastructure** - scrape targets, nodes, storage
5. **Loki deep dive** - for issues found above

## Phase 2: Triage

Walk through each issue interactively.

### Display Format

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 [1/5] OOMKilled: workstation-clustering/api-server
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Container: api-server | Pod: api-server-7b9f4-xk2ml
  Restarts: 8 in last hour | Memory limit: 2Gi
  
  Recent logs:
  > torch.cuda.OutOfMemoryError: CUDA out of memory
  
  Repo: workstation-clustering
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [C]reate bead  [S]kip  [I]nvestigate  [A]ll remaining  [Q]uit
```

### Actions

| Key | Action |
|-----|--------|
| C | Create bead with auto-generated title/description, add to fix queue |
| S | Skip this issue, move to next |
| I | Query Loki for more logs, show recent events, then re-prompt |
| A | Create beads for all remaining issues |
| Q | Stop scan, proceed to fix queue |

### Bead Creation

```python
create_beads(
    title="OOMKilled: api-server in workstation-clustering",
    description="<issue details from display>",
    labels=["crash", "oom", "workstation-clustering", "auto-detected"],
    priority=1,  # high severity
    workspace_root="~/.beads-planning",
)
```

## Phase 3: Fix (Parallel Ralph)

Dispatch `/ralph` per repository with all issues for that repo.

### Repo Mapping

**Any repo under the `imprivata-ai` GitHub org is fair game for fixes.**

```yaml
namespace → repo:
  workstation-clustering: workstation-clustering
  alert-summarizer: alert-summarizer
  ddi: drug-diversion
  argo-workflows: drug-diversion  # DDI workflows run here
  dagster: data-layer
  data-layer: data-layer
  dl-lakekeeper: data-layer
  dl-openfga: data-layer
  dl-keycloak: data-layer
  payment-processing: data-layer

  # Infrastructure (also actionable - platform repos):
  argocd: platform-argocd
  monitoring: k8s-monitoring  # k8s-monitoring, opencost, etc
  kube-system: platform-infra  # karpenter, coredns, etc
  fluent-bit: platform-infra
  robusta: platform-infra

repo_base: ~/git/imprivata/ai
github_org: imprivata-ai  # all repos under this org are in scope
beads_workspace: ~/.beads-planning
```

### Dispatch Pattern

For each repo with issues:

1. **Create worktree** using `using-git-worktrees` skill
2. **Dispatch subagent** with Ralph instruction:

   ```text
   Fix the following issues in {repo}:

   1. {issue_title} - {issue_description}
   2. ...

   Use /ralph workflow. Reference bead IDs in commits.
   ```

3. **Run in parallel** - all repos simultaneously

### Cross-Repo Dependencies

Ralph agents may discover fixes that span multiple repos.
When this happens:

1. **Agent reports cross-repo dependency** in completion message
2. **Orchestrator creates additional worktree** for the dependent repo
3. **Dispatch follow-up Ralph agent** to apply the remaining changes

**Common cross-repo patterns:**

| Issue Location | Fix Often Also Requires |
|----------------|------------------------|
| `ai-drug-diversion` (argo workflows) | `gitops-apps` (controller config) |
| `gitops-infra` (terraform/eks) | `gitops-apps` (helm values) |
| Application repo (resource needs) | `gitops-apps` or `gitops-infra` |
| `k8s-monitoring` (dashboards) | `gitops-apps` (scrape config) |

**Automatic handling:**

```text
If Ralph output contains "separate repo", "cross-repo", or "gitops-apps/gitops-infra needed":
  → Prompt: "Cross-repo dependency detected. Create worktree for {repo}? [Y/n]"
  → If yes: create worktree, dispatch follow-up agent
```

## Phase 4: Review

Walk through each repo individually after all agents complete.

### Review Display

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ [1/2] workstation-clustering
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Fixed:
    • OOMKilled: api-server → Added batch processing
    • High memory: model-loader → Implemented lazy loading

  Branch: fix/observe-2026-03-12
  Tests: ✅ 142 passed
  Files changed: 4
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [D]iff  [P]ush  [S]kip  [Q]uit
```

### Review Actions

| Key | Action |
|-----|--------|
| D | Show full diff of changes |
| P | Push branch, display PR creation link |
| S | Skip this repo, move to next |
| Q | Stop review, keep remaining worktrees |

### After Push

Display PR link for each pushed branch:

```text
Pushed: fix/observe-2026-03-12
→ https://github.com/imprivata-ai/workstation-clustering/compare/fix/observe-2026-03-12
```

## Ad-Hoc Query Planning (Two-Phase Dialogue)

When user requests a custom PromQL/LogQL query, use this workflow:

### Phase 1: Capture Intent

```text
Before generating any query:

1. What are you trying to monitor/measure?
2. Is this for alerting, dashboarding, or ad-hoc analysis?
3. What time range? What aggregation?
4. What thresholds matter (for alerting)?
```

### Phase 2: Present Query Plan

```text
┌─────────────────────────────────────────────────────────┐
│ PromQL Query Plan                                       │
│                                                         │
│ Goal: [plain English description]                       │
│                                                         │
│ Query Structure:                                        │
│   1. Start with metric: `http_requests_total`           │
│   2. Filter by: `{job="api", env="prod"}`               │
│   3. Apply function: `rate(...[5m])`                    │
│   4. Aggregate: `sum by (endpoint)`                     │
│                                                         │
│ Expected Output:                                        │
│   - Type: instant vector / range vector / scalar        │
│   - Labels: [list labels in result]                     │
│   - Value: [what the number represents]                 │
│                                                         │
│ Does this match your intentions?                        │
└─────────────────────────────────────────────────────────┘

⏸️ STOP AND WAIT FOR USER CONFIRMATION

Only generate query after plan is confirmed.
```

### PromQL Anti-Pattern Detection

When reviewing or generating queries, check for these:

| Anti-Pattern | Detection | Fix |
|--------------|-----------|-----|
| `rate()` on gauge | Metric lacks `_total`, `_count`, `_bucket` | Use directly or `avg_over_time()` |
| Missing label filters | No `{}` or empty selector | Add `{job="...", instance="..."}` |
| Averaging quantiles | `avg(metric{quantile="..."})` | Use `histogram_quantile()` with buckets |
| `irate()` over long ranges | `irate(...[1h])` | Use `rate()` for ranges > 5m |
| Regex overuse | `=~` when `=` works | Use exact match for performance |
| Counter without rate | Raw `_total` metric | Wrap in `rate()` or `increase()` |
| Missing `by` clause | `sum(rate(...))` without grouping | Add `sum by (label)(...)` |

### LogQL Anti-Pattern Detection

| Anti-Pattern | Detection | Fix |
|--------------|-----------|-----|
| Missing stream selector | No `{...}` | Add `{namespace="...", app="..."}` |
| Expensive regex first | `|~ ".*pattern.*"` early | Put cheap filters first |
| Line filter after parse | Parse then `|=` | Filter lines before parsing |
| Unbounded time range | Query without `[timerange]` | Add explicit time bounds |

### SLO/Burn Rate Reference

For alerting investigations, use Google SRE multi-window burn rates:

| Burn Rate | Budget Consumed | Time to Exhaust | Alert Severity |
|-----------|-----------------|-----------------|----------------|
| 1 | 100% over 30d | 30 days | None |
| 2 | 100% over 15d | 15 days | Low |
| 6 | 5% in 6h | 5 days | Ticket |
| 14.4 | 2% in 1h | ~2 days | Page |
| 36 | 5% in 1h | ~20 hours | Page (urgent) |

**Standard multi-window alert pattern:**

```promql
# Page-level: 2% budget in 1h (burn rate 14.4)
# Long window (1h) AND short window (5m) must both exceed
(
  (error_rate_1h) > 14.4 * allowed_error_rate
)
and
(
  (error_rate_5m) > 14.4 * allowed_error_rate
)
```

### Error→Reference Mapping

| Error Pattern | Reference | Fix |
|---------------|-----------|-----|
| `"no data"` in alert | Missing scrape targets | Check `up` metric, verify ServiceMonitor |
| `many-to-many matching` | Vector matching error | Add `on(label)` or `ignoring(label)` |
| `vector cannot contain metrics` | Wrong function usage | Check function expects instant vs range |
| High cardinality warning | Too many label values | Remove high-cardinality labels |

## Quick Reference Queries

Copy-paste ready for common investigations:

```python
# Most impactful - high restart pods
"sum by (namespace, pod) (increase(kube_pod_container_status_restarts_total[7d])) > 10"

# Pods last terminated with error
'kube_pod_container_status_last_terminated_reason{reason!="Completed"}'

# Failed K8s jobs
"kube_job_status_failed > 0"

# Scrape targets down
"up == 0"

# Memory anti-pattern (req == limit)
'kube_pod_container_resource_requests{resource="memory"} / kube_pod_container_resource_limits{resource="memory"} == 1'

# Loki: OOMKilled
'{namespace="argo-workflows"} |~ `exit code 137|OOMKilled`'
```

## Integration

**Uses these skills:**

- `using-git-worktrees` - Isolated workspaces per repo
- `dispatching-parallel-agents` - Concurrent subagent execution
- `/ralph` command - Full TDD workflow per issue

**MCP servers required:**

- `prometheus-prod` or `prometheus-nonprod`
- `grafana` (for Loki logs, datasourceUid:
  `cdu13x568whdsd` for prod)
- `beads` (for issue tracking, workspace:
  `~/.beads-planning`)
