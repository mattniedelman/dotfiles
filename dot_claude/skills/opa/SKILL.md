---
name: opa
description: Use when working with Open Policy Agent -- writing Rego policies, deploying OPA for Kubernetes admission control (plain webhook or Gatekeeper), wiring up Envoy AuthZ sidecars, designing bundle distribution, testing policies, or choosing between OPA and alternatives (Cedar, OpenFGA, Casbin)
allowed-tools: Read, Bash(opa:*), Edit, Write
---

# Open Policy Agent (OPA)

## When to Use

Activate when the user is:

- Writing or debugging a Rego policy
- Setting up OPA for Kubernetes admission control (plain webhook or Gatekeeper)
- Wiring OPA-Envoy for service mesh authz
- Designing bundle distribution or data loading
- Writing or running policy tests (`opa test`)
- Troubleshooting unexpected `undefined` results or policy behavior
- Choosing between OPA and an alternative (Cedar, OpenFGA, Casbin, CEL)
- Sizing or hardening an OPA deployment for production

**First step on activation:** Determine which task applies (below) before
writing any code. One clarifying question is better than ten wrong lines.

## When NOT to Use

- **Only need simple K8s label/field validation** -- CEL ValidatingAdmissionPolicy (GA in K8s v1.30) does this in-process with no external dependency.
- **Authorization is purely relationship-based** ("can Alice access this doc given team membership graphs?") -- OpenFGA's graph traversal model is a better fit than manual Rego iteration.
- **Need an embedded in-process library with zero network overhead** -- Casbin is a direct language import; OPA's sidecar model adds latency and operational complexity that aren't justified.
- **Need formal proof of policy correctness** -- Cedar's automated reasoning tools can prove security properties; Rego cannot.
- **Single service with simple RBAC and no cross-cutting policy needs** -- the OPA sidecar is overhead you don't need; implement RBAC directly in the service.

## Essential Principles

**`undefined` is not `false`.**
If no rule produces a value, OPA returns `undefined` -- not `false` and not
an error. Callers that treat a missing result as "allowed" or "denied" will
be wrong. Always set `default allow := false` (or the equivalent) when the
absence of a matching rule should be a denial.

**`allow` and `deny` are not keywords.**
They carry no built-in semantics and are not automatically contradictory. If
you want deny to override allow, write that explicitly:
`final_allow if { allow; not deny }`.

**Bundle roots own their namespace entirely.**
Omitting `roots` from the bundle manifest defaults to `[""]`, which means
ALL policy and data must come from that bundle. Specify roots explicitly when
running multiple bundles.

**Memory overhead is 20x.**
OPA expands JSON data into Go maps/slices/strings. 8 MB of JSON consumes
~160 MB RAM. 100,000 ACL rules consume ~1.1 GB. Plan for this before loading
large data sets.

**Partial evaluation is free optimization.**
`opa build -O2` pre-computes everything that doesn't depend on `input`.
Always build optimized bundles for production hot paths.

## Routing

Choose the task that matches and follow its steps:

### 1. Write or debug a Rego policy

1. Ask what the policy needs to enforce and what input looks like.
2. Sketch the rule structure before writing full Rego. Confirm the mental
   model with the user.
3. Write the policy using `import rego.v1`. Set `default allow := false`.
4. Write at least one `test_` rule per code path.
5. Run `opa test -v ./policies/` to confirm.
6. For built-in function questions, read
   `{baseDir}/references/rego-builtins.md`.

Common pitfalls checklist:
- `undefined` vs `false` -- have a default rule
- `allow`/`deny` not contradictory unless you make them so
- Nested iteration: use `some` with named vars to avoid cross-products
- `with` mock arity must match exactly

**Done when:** `opa test` passes with coverage on all decision branches, and
the user can evaluate a representative input against the policy without
`undefined` surprises.

### 2. Kubernetes admission control

**Choose deployment model first:**

| Need | Choice |
|------|--------|
| Parameterized policies, audit-retroactive compliance | Gatekeeper |
| Direct bundle/decision-log/status API access | Plain OPA webhook |
| Only simple label/field checks, no external service | CEL ValidatingAdmissionPolicy |

**For Gatekeeper** -- read `{baseDir}/references/alternatives.md` for the
CEL comparison, then write:
- `ConstraintTemplate` with Rego in `spec.targets[].rego`
- `Constraint` to instantiate with parameters
- Add `violation[{"msg": msg}]` rule (not `allow`)
- Consider disaggregated deployment for production

**For plain OPA webhook:**
- Register `ValidatingWebhookConfiguration`
- Use kube-mgmt sidecar to replicate K8s resources
- Input is `AdmissionReview`; return `{"response": {"allowed": true/false}}`
- Admission phases: mutating first, validating second

**Done when:** A test admission request is accepted or rejected as expected,
and the webhook is registered and reachable from the API server.

### 3. Envoy AuthZ sidecar

Deploy `openpolicyagent/opa:latest-envoy` as a sidecar. Configure
`plugins.envoy_ext_authz_grpc.path` to point at the decision rule.

Decision return formats:
- `true` -- allow
- `false` -- deny (HTTP 403)
- Object: `{"allowed": true, "headers": {...}, "body": "...", "http_status": 200}`

**Done when:** A test request through Envoy is accepted or rejected by the
OPA policy, verified via Envoy access logs showing the ext_authz decision.

### 4. Bundle design and distribution

Read `{baseDir}/references/bundles.md` for full details. Key decisions:

- **Roots:** Set explicit roots when running multiple bundles
- **Persistence:** Set `persist: true` for cold-start resilience
- **Signing:** Enable in production -- `opa build --signing-key`
- **Delta bundles:** Data-only updates; not persisted; not for policies

**Done when:** OPA polls the bundle server, activates successfully
(`/v1/status` shows `last_successful_activation`), and the REST API rejects
writes to bundle-owned paths.

### 5. Policy testing

```rego
# test_ prefix required; todo_ = SKIPPED
test_admin_allowed if {
    allow with input as {"user": "alice", "role": "admin"}
}

# Mock data with `with`
test_deny_unknown if {
    not allow with input as {"user": "unknown"}
              with data.roles as {}
}
```

```bash
opa test -v ./policies/
opa test --coverage ./policies/
```

Mock arity must match exactly -- replacements and replaced functions must
have the same number of arguments.

**Done when:** `opa test` exits 0, all branches have test coverage, and no
`todo_` tests remain for the feature under review.

### 6. Choosing between OPA and alternatives

Read `{baseDir}/references/alternatives.md` for the full comparison. Short
version:

- **Relationship graphs** ("can Alice edit this doc given team membership?") -- OpenFGA
- **Formal verification / provable correctness** -- Cedar
- **Embedded in-process, no sidecar** -- Casbin
- **Simple K8s validation only** -- CEL ValidatingAdmissionPolicy (K8s v1.30+)
- **General-purpose, arbitrary JSON data, K8s + services unified** -- OPA

**Done when:** The user has a clear recommendation with the deciding factors
named, and understands the trade-offs they are accepting.

### 7. Production sizing and hardening

Read `{baseDir}/references/production.md` for the full checklist. Summary:

- Size memory for 20x JSON overhead (see table above)
- Set readiness probe to `/health?bundles=true`
- Enable bundle signing
- Mask PII in decision logs before they leave the pod
- Use disaggregated Gatekeeper deployment in large clusters
- Bind management API to loopback; expose only data query externally

**Done when:** All items in the production checklist in
`{baseDir}/references/production.md` are addressed or explicitly deferred
with a rationale.

## Success Checklist

Before closing any OPA task, confirm:

- [ ] `default allow := false` (or equivalent) is set -- no implicit allow
- [ ] `allow` and `deny` interaction is explicit if both rules exist
- [ ] Bundle `roots` field is set explicitly (not defaulting to `[""]` unintentionally)
- [ ] `opa test` passes for all decision branches
- [ ] Memory overhead is accounted for if loading >1 MB of JSON data
- [ ] Decision logs are configured with PII masking for any production deployment

## Quick Reference

```rego
package authz

import rego.v1

default allow := false

allow if {
    input.method == "GET"
    input.path[0] == "public"
}

allow if {
    some role in data.roles[input.user]
    role == "admin"
}
```

```bash
# Evaluate
echo '{"user":"alice","method":"GET","path":["public"]}' |
	opa eval -I -d policy.rego 'data.authz.allow'

# Test
opa test -v ./policies/

# Build optimized bundle
opa build -O2 -b ./policies/ -o bundle.tar.gz

# Start server
opa run --server --bundle bundle.tar.gz
```

## Performance Reference

| Data Size | ~RAM | Notes |
|-----------|------|-------|
| 8 MB JSON (100k objects) | ~160 MB | 20x overhead vs compact |
| 10,000 ACL rules | ~130 MB | |
| 100,000 ACL rules | ~1.1 GB | Plan at design time |

Simple RBAC evaluation: ~35 us median, ~134 us p99.
Per-request evaluation is single-threaded and CPU-bound.
Server parallelizes requests across cores (cap with `GOMAXPROCS`).

## Reference Files

| File | Contents |
|------|---------|
| [references/rego-builtins.md](references/rego-builtins.md) | Built-in functions -- strings, arrays, sets, JSON, time, crypto, OPA-specific |
| [references/bundles.md](references/bundles.md) | Bundle server setup, OCI format, S3, delta bundles, signing |
| [references/decision-logging.md](references/decision-logging.md) | Log schema, masking sensitive fields, remote sink config |
| [references/rest-api.md](references/rest-api.md) | Policy CRUD, data API, compile endpoint, query, batch |
| [references/partial-evaluation.md](references/partial-evaluation.md) | Unknowns, support rules, the compile API, optimization levels |
| [references/alternatives.md](references/alternatives.md) | OPA vs Cedar vs OpenFGA vs Casbin vs CEL -- full feature matrix |
| [references/production.md](references/production.md) | Memory sizing, GOMAXPROCS, TLS, bundle signing, Prometheus, profiling |
