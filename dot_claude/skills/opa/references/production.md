# OPA Production Checklist

## Memory Sizing

Raw JSON data inflates ~20x in OPA's Go runtime (maps, slices, strings vs.
compact serialized bytes):

| Data Size | ~RAM |
|-----------|------|
| 8 MB JSON (100k objects) | ~160 MB |
| 10,000 ACL rules | ~130 MB |
| 100,000 ACL rules | ~1.1 GB |

**Rules:**
- Measure with `GODEBUG=gctrace=1` or expose `/metrics` and watch
  `go_memstats_alloc_bytes`.
- If data exceeds ~50 MB JSON, profile before deploying. Consider sharding
  data across multiple OPA instances or using partial evaluation to avoid
  loading all data.
- Delta bundles reduce re-download cost but not in-memory cost.

## CPU and Concurrency

- Per-request evaluation is single-threaded and CPU-bound.
- The OPA server parallelizes concurrent requests across all available cores.
- Default: `GOMAXPROCS = number of CPU cores`.
- To cap CPU usage: `GOMAXPROCS=4 opa run --server ...`

**Optimization pipeline:**
1. Baseline with `opa bench` in CI.
2. Build with `-O2` for hot policies.
3. Profile with `--profile` flag; look for hot built-ins or large iterations.
4. Consider Wasm for edge/browser; consider Go embedded for same-process.

## TLS

```bash
opa run --server \
  --tls-cert-file /certs/server.crt \
  --tls-private-key-file /certs/server.key \
  # mTLS: require client cert
  --tls-ca-cert-file /certs/ca.crt
```

For Kubernetes: mount certs via a Secret. Rotate with cert-manager.

With mTLS, client identity is in `input.identity` (the cert subject CN or SAN).

## Bundle Configuration

```yaml
bundles:
  authz:
    resource: "/bundles/authz.tar.gz"
    persist: true              # survive pod restarts on bundle server outage
    polling:
      min_delay_seconds: 10
      max_delay_seconds: 60
    signing:
      verification_key_path: /etc/opa/public.pem
```

**Checklist:**
- [ ] `persist: true` so OPA starts from cached bundle if server is unavailable
- [ ] Bundle signing enabled in production
- [ ] Separate service account / IRSA / workload identity for bundle access
- [ ] Monitor `last_successful_activation` via `/v1/status`

## Health Probe Configuration (Kubernetes)

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8181
  initialDelaySeconds: 10
  periodSeconds: 15

readinessProbe:
  httpGet:
    path: /health?bundles=true   # only ready when bundles loaded
    port: 8181
  initialDelaySeconds: 10
  periodSeconds: 15
  failureThreshold: 3
```

Without `?bundles=true`, OPA reports ready before policies are loaded and
you'll get unexpected `undefined` responses.

## Prometheus Metrics

OPA exposes Prometheus metrics at `/metrics`:

```yaml
# Key metrics to watch
opa_request_duration_seconds        # request latency histogram
opa_request_total                   # request count by path/code
go_memstats_alloc_bytes             # heap allocation
go_gc_duration_seconds              # GC pauses (watch for spikes)
```

```yaml
# prometheus.io scrape annotations
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8181"
  prometheus.io/path: "/metrics"
```

## Decision Logging in Production

```yaml
decision_logs:
  service: log-sink
  reporting:
    min_delay_seconds: 5
    max_delay_seconds: 60
    buffer_size_limit_bytes: 10000000   # 10 MB -- drop oldest if exceeded
  mask_decision:
    body: |
      package system.log
      mask contains "/input/headers/authorization"
      mask contains "/input/password"
```

- Always run a remote sink in production; console logs don't survive pod
  restarts.
- Mask secrets and PII before they leave the pod.
- Decision IDs link OPA decisions to upstream service request IDs.

## Resource Limits (Kubernetes)

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "256Mi"    # adjust based on data size
  limits:
    cpu: "500m"
    memory: "512Mi"    # OOM kill if exceeded; size for your data
```

Never set memory limit below your measured steady-state RSS + 20% headroom.
OPA does not gracefully degrade when approaching the memory limit.

## Profiling

```bash
# CPU profile (30s)
curl http://localhost:8181/debug/pprof/profile?seconds=30 -o cpu.prof
go tool pprof -http=:8080 cpu.prof

# Heap profile
curl http://localhost:8181/debug/pprof/heap -o heap.prof
go tool pprof -http=:8080 heap.prof

# Policy-level profiling
opa eval --profile --bundle ./policies/ 'data.authz.allow' \
  -d '{"input": {"user": "alice"}}' 2>&1 | head -30
```

## Security Hardening

- [ ] Disable the management API on the external interface; expose only the
  data query endpoint. Use `--addr` to bind query to `0.0.0.0:8181` and
  `--management-addr` to bind management to `127.0.0.1:8282`.
- [ ] Use mTLS between services and OPA -- bearer tokens are acceptable but
  mTLS is stronger.
- [ ] Sign bundles so a compromised bundle server cannot inject policy.
- [ ] Run OPA as a non-root user with a read-only root filesystem.
- [ ] Restrict `http.send` in policies -- it makes OPA I/O-bound and can be
  used to exfiltrate data or probe internal services.
- [ ] Set `--max-body-bytes` to limit request body size.

## Gatekeeper Production Notes

- Use disaggregated deployment (`--operation=webhook`, `--operation=audit`)
  so an audit OOM does not kill the admission webhook.
- Set `--audit-interval=60` (default) or longer if audit is CPU-intensive.
- Monitor constraint `.status.totalViolations` -- rising count means
  pre-existing non-compliant resources are accumulating.
- Use `ConstraintTemplate` `.spec.crd.spec.validation.openAPIV3Schema` to
  validate parameters at constraint admission time, not at evaluation time.
