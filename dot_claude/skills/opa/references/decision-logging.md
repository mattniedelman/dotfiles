# OPA Decision Logging

Full reference: https://www.openpolicyagent.org/docs/latest/management-decision-logs/

## Log Entry Schema

```json
{
  "decision_id": "abc123",
  "bundle_name": "authz",
  "path": "data.authz.allow",
  "input": { "user": "alice", "action": "read", "resource": "orders/42" },
  "result": true,
  "requested_by": "10.0.0.5:51234",
  "timestamp": "2024-01-01T00:00:00Z",
  "metrics": {
    "timer_rego_query_eval_ns": 42000
  },
  "erased": [],
  "masked": []
}
```

## Config

```yaml
decision_logs:
  console: true                    # also print to stdout (default: false)
  service: my-log-sink             # send to remote service
  resource: /logs                  # path on the service

  # Mask PII before logging
  mask_decision:
    body: |
      package system.log
      import rego.v1

      # Mask input fields containing PII
      mask contains "/input/ssn"
      mask contains "/input/credit_card"

      # Erase result entirely for certain queries
      # erase contains "/result" if { ... }

services:
  my-log-sink:
    url: https://logs.example.com
    credentials:
      bearer:
        token: "${LOG_TOKEN}"
```

## Console Logging (development)

```bash
opa run --server \
  --set=decision_logs.console=true \
  --bundle ./policies/
```

Logs go to stdout as JSON lines. Useful in development; in production use a
remote sink so logs survive pod restarts.

## Masking Sensitive Fields

The `system.log` package controls masking before the log entry is shipped.
Two operations:

- `mask` -- replaces value with `""` and records the path in `masked[]`
- `erase` -- removes the key entirely and records the path in `erased[]`

```rego
package system.log
import rego.v1

# Always mask authorization headers
mask contains "/input/headers/authorization"

# Mask token fields by suffix
mask contains path if {
  some path
  endswith(path, "/token")
}

# Erase result for internal health queries
erase contains "/result" if {
  input.path == ["health"]
}
```

## Remote Sink

OPA batches log entries and ships them to the configured service:

```yaml
decision_logs:
  service: log-service
  reporting:
    min_delay_seconds: 5
    max_delay_seconds: 60
    buffer_size_limit_bytes: 10000000   # 10 MB in-memory buffer

services:
  log-service:
    url: https://logs.example.com
    credentials:
      bearer:
        token_path: /var/run/secrets/log-token
```

OPA sends `POST /logs` with a JSON array of decision log entries. Implement
this endpoint yourself or use Styra DAS, Elasticsearch, or a log aggregator
that accepts HTTP POST.

## Custom Plugins

For advanced routing (e.g., different sinks for different policy paths),
implement the `plugins.Logger` interface in Go and register it:

```go
func (p *MyLogger) Log(ctx context.Context, event logs.EventV1) error {
    // route or enrich as needed
    return nil
}
```

## Correlation with Traces

`decision_id` is also available inside Rego via `opa.runtime()` in some
contexts. Log the decision ID in your application's request log to correlate
app-side events with OPA decisions.
