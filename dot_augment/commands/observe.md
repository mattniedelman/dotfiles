---
description: Scan observability stack for production issues, create beads, dispatch parallel fixes
argument-hint: [prod|nonprod|all]
---

# Observability-Driven Development

Scan Prometheus and Loki for production issues, triage interactively, and
dispatch parallel Ralph workflows to fix them.

## Execution

Use the `observability-driven-development` skill for full workflow details.

### Phase 1: Scan

Query the specified environment (default:
`prod`) for issues:

**MCP servers:**

- `prometheus-prod` or `prometheus-nonprod` for metrics
- `grafana` for Loki logs

**Signals to query (in order):**

1. **Critical:** High restarts (7d >10), last terminated errors, failed K8s jobs
2. **Firing alerts:** Check Grafana alert rules
3. **Resource pressure:** Memory pressure (>95%), CPU throttling
4. **Infrastructure:** Scrape targets down, node conditions, PVC issues
5. **Loki deep dive:** Exit code 137 (OOM), error logs for affected namespaces

For each signal, run the PromQL/LogQL queries defined in the skill.
Collect results, extract namespace/pod/container info.
Group by severity (🔴 critical → 🟠 high → 🟡 medium).

### Phase 2: Triage

For each issue found, display details and prompt:

```text
🔴 [1/N] {signal}: {namespace}/{container}
   {details}
   Repo: {mapped_repo}

   [C]reate bead  [S]kip  [I]nvestigate  [A]ll remaining  [Q]uit
```

**Repo mapping:**

| Namespace | Repository |
|-----------|------------|
| workstation-clustering | workstation-clustering |
| alert-summarizer | alert-summarizer |
| ddi, argo-workflows | drug-diversion |
| dagster, data-layer, dl-* | data-layer |
| argocd, monitoring, kube-system | platform (infra) |

Repo base:
`~/git/imprivata/ai`

**Create beads in:** `~/.beads-planning`

See skill for complete namespace-to-repo mapping.

### Phase 3: Fix

After triage, show fix queue summary and ask to proceed.

For each repo with issues:

1. Create worktree using `using-git-worktrees` skill
2. Dispatch `/ralph` subagent with all issues for that repo
3. Run repos in parallel using `dispatching-parallel-agents` pattern

Wait for all agents to complete.

### Phase 4: Review

Walk through each repo individually:

```text
✅ [1/N] {repo}
   Fixed: {issue_summaries}
   Branch: fix/observe-{date}
   Tests: {test_results}

   [D]iff  [P]ush  [S]kip  [Q]uit
```

After push, display PR creation link.

## Quick Reference

```text
/observe          # Scan prod
/observe nonprod  # Scan nonprod
/observe all      # Scan both environments
```

## See Also

- `observability-driven-development` skill - Full workflow details
- `using-git-worktrees` skill - Worktree creation
- `dispatching-parallel-agents` skill - Parallel execution
- `/ralph` command - TDD workflow per issue
