# Policy Engine Alternatives

## Decision Matrix

| Dimension | OPA + Rego | Cedar (AWS) | OpenFGA | Casbin | CEL (K8s VAP) |
|-----------|-----------|-------------|---------|--------|---------------|
| **Model** | General-purpose policy | Attribute-based (ABAC) | Relationship-based (ReBAC) | Multi-model (RBAC, ABAC, ACL) | Expression eval |
| **Policy language** | Rego (Datalog-inspired) | Cedar (declarative, typed) | Tuple-based authorization model | PERM model in .conf + .csv | CEL expressions |
| **Formal verification** | No | Yes (automated reasoning) | No | No | No |
| **Deployment** | Sidecar / server / library | Library or AWS managed service | Server (self-hosted or managed) | Embedded library | In-process (K8s only) |
| **Graph traversal** | Manual in Rego | No | Yes (built-in) | Partial (RBAC hierarchy) | No |
| **K8s native** | Via webhook / Gatekeeper | No | No | No | Yes (GA v1.30) |
| **Performance** | ~35 us median (simple RBAC) | Sub-ms (Cedar claims) | Zanzibar-inspired; built for scale | In-process; varies | In-process; very fast |
| **Learning curve** | High (Rego) | Medium | Medium (model design) | Low-Medium | Low (if you know CEL) |
| **CNCF** | Graduated (2021) | No | CNCF sandbox (2023) | No | Part of K8s |

## OPA

**Use when:**
- You need a general-purpose policy engine that works across K8s, APIs,
  microservices, and CI/CD.
- Policies need to reason over arbitrary JSON data (not just user-resource
  tuples).
- You want a large ecosystem and proven production track record.
- You're already running on K8s and want Gatekeeper.

**Avoid when:**
- Your authorization model is purely relationship-based ("can user X access
  resource Y given a relationship graph?") -- OpenFGA handles this better.
- You need formal proof that your policy is correct -- Cedar provides
  automated reasoning.
- You want an embedded library with zero network overhead -- Casbin or Cedar.

## Cedar

Source: https://www.cedar-policy.com / https://github.com/cedar-policy/cedar

**Core differentiator:** Designed for automated reasoning. Cedar's type system
and evaluation semantics are amenable to formal analysis tools that can prove
properties like "no user can escalate to admin without explicit grant" or
"policy A is equivalent to policy B."

**AWS Verified Permissions** is Cedar hosted as a managed service -- it
externalizes authorization from application code and supports centralized
policy management with distributed decision-making.

```cedar
permit (
  principal == User::"alice",
  action in [Action::"read", Action::"write"],
  resource in Folder::"shared"
);
```

**Use when:**
- You need provable security guarantees (e.g., regulated environments).
- You're building on AWS and want a managed service.
- Your model maps naturally to principal/action/resource triples.

## OpenFGA

Source: https://openfga.dev / https://github.com/openfga/openfga

**Core differentiator:** Built on the Google Zanzibar paper. Models
authorization as a graph of relationships between objects. Answers "does
user X have relation Y to object Z?" via graph traversal.

Zanzibar (Google's system) handles trillions of ACL entries and millions of
requests/second with p95 < 10ms.

```
type document
  relations
    define owner: [user]
    define editor: [user] or owner
    define viewer: [user] or editor
```

**Use when:**
- Authorization is fundamentally about relationships: "Alice is an editor of
  doc:42 because she's a member of team:engineering which has editor on doc:42."
- You have deep permission hierarchies (folders, orgs, teams, projects).
- You need consistent, low-latency answers across a large object graph.

**Avoid when:**
- Policies need to reason about request attributes (IP, time of day, HTTP
  method) not captured in the relationship graph -- this requires OPA or Cedar.

## Casbin

Source: https://casbin.org / https://github.com/casbin/casbin

**Core differentiator:** Embedded library, not a sidecar or service. Policy
enforcement happens inside your process via a direct language import (Go,
Python, Java, Node, etc.). Supports 11+ access control models including ACL
variants, RBAC with domain/tenant support, and ABAC.

```go
e, _ := casbin.NewEnforcer("model.conf", "policy.csv")
ok, _ := e.Enforce("alice", "/data/1", "read")
```

**Use when:**
- You want zero-latency in-process enforcement with no network hop.
- Your model is well-represented by RBAC, ABAC, or ACL variants.
- You want a simple library API without deploying infrastructure.

**Avoid when:**
- You need policy hot-reload across multiple service instances without
  restarting -- OPA bundles handle this better.
- Policy authoring by non-developers is a requirement.

## Kubernetes ValidatingAdmissionPolicy (VAP) + CEL

Native to Kubernetes (GA since v1.30, enabled by default).

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata: {name: require-team-label}
spec:
  matchConstraints:
    resourceRules:
      - apiGroups: ["*"]
        apiVersions: ["*"]
        resources: ["namespaces"]
        operations: ["CREATE", "UPDATE"]
  validations:
    - expression: "'team' in object.metadata.labels"
      message: "namespace must have a 'team' label"
```

**Use when:**
- Simple K8s admission validation without an external webhook.
- CEL expressions are sufficient (most label/annotation/field checks are).
- You want no external dependency for admission control.

**Avoid when:**
- Policies need external data (user databases, OPA data store).
- You need mutation (CEL VAP is validation-only).
- Complex logic exceeds what CEL can express (it's not Turing-complete).
- You need the Gatekeeper audit-retroactive-compliance feature.

## Choosing

```
Need K8s admission control?
  Simple label/field checks only? --> CEL ValidatingAdmissionPolicy
  Parameterized library + audit?  --> OPA Gatekeeper
  Direct bundle/log access?       --> Plain OPA webhook

Need service/API authorization?
  User-resource relationships?    --> OpenFGA
  Formal correctness proofs?      --> Cedar / AWS Verified Permissions
  Embedded in-process?            --> Casbin
  Complex rules over JSON data?   --> OPA
  Already using OPA for K8s?      --> OPA (unified toolchain)
```
