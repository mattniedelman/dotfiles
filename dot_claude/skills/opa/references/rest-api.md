# OPA REST API

Full reference: https://www.openpolicyagent.org/docs/latest/rest-api/

## Health and Status

```bash
GET /health                    # 200 OK if healthy
GET /health?bundles=true       # 200 only if all bundles activated
GET /health?plugins=true       # 200 only if all plugins OK
GET /v1/status                 # bundle/plugin status detail
```

```bash
curl http://localhost:8181/health?bundles=true
```

## Data API

```bash
# Read
GET  /v1/data[/<path>]
# Write (replaces entire path)
PUT  /v1/data/<path>
# Patch (JSON Patch RFC 6902)
PATCH /v1/data/<path>
# Delete
DELETE /v1/data/<path>
```

```bash
# Read all data
curl http://localhost:8181/v1/data

# Read specific path
curl http://localhost:8181/v1/data/authz/roles

# Write data
curl -X PUT http://localhost:8181/v1/data/authz/roles \
  -H 'Content-Type: application/json' \
  -d '{"alice": ["admin"], "bob": ["reader"]}'

# Patch
curl -X PATCH http://localhost:8181/v1/data/authz/roles \
  -H 'Content-Type: application/json' \
  -d '[{"op": "add", "path": "/charlie", "value": ["reader"]}]'
```

**Note:** Bundle-owned paths cannot be modified via the REST API by default.

## Policy API

```bash
# List policies
GET  /v1/policies
# Read policy
GET  /v1/policies/<id>
# Write policy (Rego source)
PUT  /v1/policies/<id>
# Delete policy
DELETE /v1/policies/<id>
```

```bash
# Upload a policy
curl -X PUT http://localhost:8181/v1/policies/authz \
  -H 'Content-Type: text/plain' \
  --data-binary @authz.rego
```

## Query API -- evaluate a rule

```bash
POST /v1/data[/<path>]
Content-Type: application/json

{
  "input": {
    "user": "alice",
    "action": "read",
    "resource": "orders/42"
  }
}
```

Response:

```json
{
  "result": true,
  "decision_id": "abc123"
}
```

Request options:

```json
{
  "input": { ... },
  "strict-builtin-errors": false,   // treat builtin errors as undefined vs. halt
  "instrument": false,               // include performance instrumentation
  "metrics": false,                  // include timer metrics
  "provenance": false,               // include policy/data version info
  "explain": "off"                   // "off" | "full" | "notes" | "fails"
}
```

## Ad-hoc Query API

```bash
POST /v1/query
Content-Type: application/json

{
  "query": "data.authz.allow == true",
  "input": { "user": "alice", "action": "read" }
}
```

Or via GET (URL-encode the query):

```bash
GET /v1/query?q=data.authz.allow+%3D%3D+true&input=%7B%22user%22%3A%22alice%22%7D
```

## Compile API (partial evaluation)

```bash
POST /v1/compile
Content-Type: application/json

{
  "query": "data.authz.allow == true",
  "input": {
    "user": "alice"
  },
  "unknowns": ["input.resource", "input.action"]
}
```

Returns a partial evaluation result: the query residual after substituting
known values. Useful for pushing filtering down to data stores.

## Batch Data API

```bash
POST /v1/data
Content-Type: application/json

{
  "requests": [
    {"path": "/authz/allow", "input": {"user": "alice", "action": "read"}},
    {"path": "/authz/allow", "input": {"user": "bob",   "action": "write"}}
  ]
}
```

Evaluates multiple queries in a single HTTP round trip.

## Provenance

Adding `"provenance": true` to a query request returns:

```json
{
  "result": true,
  "provenance": {
    "version": "0.68.0",
    "build_commit": "abc123",
    "bundles": {
      "authz": { "revision": "20240101-v1" }
    }
  }
}
```

## Authentication

```yaml
# Bearer token
authorization:
  basic:
    default_decision: data.system.authz.allow

server:
  authentication:
    token:
      secret: "my-shared-secret"
```

For production, use mTLS with `--tls-cert-file`, `--tls-private-key-file`,
and `--tls-ca-cert-file`. Client cert identity is available as
`input.identity` in the authz policy.
