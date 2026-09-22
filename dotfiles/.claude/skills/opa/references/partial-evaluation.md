# OPA Partial Evaluation

Full reference: https://www.openpolicyagent.org/docs/latest/partial-evaluation/

## Concept

Partial evaluation lets you pre-compute the parts of a policy that don't
depend on runtime inputs. You declare some inputs as "unknowns"; OPA
evaluates everything it can and returns a residual query.

Use case: push row-level filtering down to a SQL/NoSQL query instead of
fetching all rows and filtering in OPA.

```
Policy + known inputs + unknowns --> residual query (filter expression)
```

## The Compile API

```bash
POST /v1/compile
{
  "query": "data.authz.allow == true",
  "input": {
    "user": "alice",
    "action": "read"
  },
  "unknowns": ["data.resources"]
}
```

Response -- residual query over the unknown:

```json
{
  "result": {
    "queries": [
      [
        {"index": 0, "terms": [{"type": "ref", "value": [{"type": "var", "value": "data"}, {"type": "string", "value": "resources"}, ...]}]}
      ]
    ]
  }
}
```

You translate this residual into a database filter predicate.

## Build-time Optimization (`opa build -O`)

`-O` bakes partial evaluation into a bundle at build time:

| Level | What happens |
|-------|-------------|
| `-O0` | No optimization (default) |
| `-O1` | Inline rules whose values don't depend on unknowns |
| `-O2` | Also inline unknown-dependent virtual docs (conditional), copy propagation, inline certain negated statements |

```bash
# Build optimized bundle (unknowns = input by convention)
opa build -O2 -e 'authz/allow' -b ./policies/ -o optimized.tar.gz
```

Optimized bundles evaluate faster because constant sub-expressions are
pre-computed. The trade-off: the bundle is specialized -- if you change data
(not just input), you may need to rebuild.

## Unknowns

By default, OPA treats `input` as the only unknown when building. You can
declare additional unknowns:

```bash
opa build -O2 \
  --unknowns input \
  --unknowns data.users \
  -e 'authz/allow' \
  -b ./policies/
```

Rules that only reference `data.roles` (not in unknowns) will be inlined
completely. Rules that reference `data.users` (unknown) produce residual
support rules.

## Support Rules

When a rule cannot be fully inlined because it references an unknown, OPA
emits a "support rule" -- a synthetic policy rule in the residual that
preserves the partial result:

```rego
# Original
allow if {
  role := data.users[input.user]
  role == "admin"
}

# After partial eval with data.users unknown:
# Support rule: allow depends on data.users[input.user] == "admin"
```

Support rules are valid Rego; they can be further compiled or interpreted.

## Row-Level Security Pattern

```rego
package authz

# Policy: user can read resources they own, or public resources
allow if {
  data.resources[input.resource_id].owner == input.user
}

allow if {
  data.resources[input.resource_id].public == true
}
```

With `data.resources` as unknown, partial evaluation returns a filter
expression you can translate to SQL:

```sql
WHERE owner = 'alice' OR public = true
```

Libraries like `opa-sql-filter` automate this translation.

## Limitations

- Not all Rego is partially evaluable. Built-ins with side effects
  (`http.send`, `time.now_ns`) block inlining.
- Negation (`not`) with unknowns can produce support rules that are harder
  to translate to DB filters.
- Very complex policies may produce large residuals that negate the
  performance benefit.
- `-O2` "may" inline unknown-dependent virtual docs -- it's conditional, not
  guaranteed.
