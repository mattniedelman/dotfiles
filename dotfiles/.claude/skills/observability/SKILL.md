---
name: observability
description: Use when implementing observability - error handling, structured logging, metrics, traces, correlation IDs, and alerting
---

# Observability

Guide for error handling, structured logging, and the three pillars of
observability.

## When to Use

Use this skill when:

- Implementing error handling patterns
- Adding logging to applications
- Setting up observability infrastructure
- Designing alerting and monitoring
- Implementing correlation/tracing

## Error Handling

### Specific Exception Types

```python
# ✅ Specific exceptions
class UserNotFoundError(Exception):
    """Raised when user cannot be found."""


class InvalidCredentialsError(Exception):
    """Raised when authentication fails."""


def get_user(user_id: str) -> User:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise UserNotFoundError(f"User {user_id} not found")
    return user
```

### Provide Context

```python
# ✅ Rich context
raise ValidationError(
    f"Invalid email format: {email}", field="email", value=email, user_id=user_id
)

# ❌ No context
raise ValidationError("Invalid email")
```

### Graceful Degradation

Degradation must be visible. When you fall back to cached data, signal it on
every channel: emit a metric, log with context, and mark the response itself so
the caller can tell it is serving stale data -- never return a silent fallback.

```python
def get_user_profile(user_id: str) -> UserProfile:
    try:
        return external_api.fetch_profile(user_id)
    except ExternalAPIError as e:
        # Signal degradation: metric + log + marked response
        metrics.increment(
            "user_profile.degraded", tags={"reason": "external_api_error"}
        )
        logger.warning(f"External API failed, serving stale cache: {e}")
        profile = cache.get(f"profile:{user_id}")
        if not profile:
            raise UserProfileUnavailableError(f"Cannot fetch profile for {user_id}")
        # Mark the response so callers know it is degraded/stale
        profile.degraded = True
        profile.degraded_reason = "external_api_unavailable"
        return profile
```

## Structured Logging

### Log Levels

| Level | Use |
|-------|-----|
| DEBUG | Detailed diagnostic information |
| INFO | User actions, system events |
| WARNING | Degraded performance, using fallback |
| ERROR | Handled exceptions, failed operations |
| CRITICAL | System failures, data corruption |

### What to Log

```python
# ✅ Log these
logger.info("user_created", user_id=user.id, email=user.email)
logger.warning("rate_limit_exceeded", user_id=user.id, endpoint="/api/data")
logger.error("database_connection_failed", error=str(e), retry_count=3)

# ❌ NEVER log sensitive data
logger.info(f"User logged in with password: {password}")  # NEVER
logger.debug(f"API key: {api_key}")  # NEVER
```

### Correlation IDs

Bind a request-scoped correlation ID so every log line within a request carries
it. For the structlog + contextvars implementation, see
[python-otel.md](python-otel.md).

## Three Pillars of Observability

1. **Logs**:
   What happened (events, errors, debug info)
2. **Metrics**:
   How much/how many (counters, gauges, histograms)
3. **Traces**:
   Where time was spent (request flow, dependencies)

### Correlation

- Consistent identifiers (request_id, user_id, trace_id)
- Link logs to traces via trace context
- Include trace_id in log messages
- Use OpenTelemetry for unified correlation
- Prefer auto-instrumentation

## OpenTelemetry Auto-Instrumentation

OTEL layers on top of Python logging - it does not replace it, and it does NOT
control your app's log level (you still need Python logging config). It adds
`trace_id` / `span_id` attributes to log records, automatic spans for frameworks
(FastAPI, SQLAlchemy, boto, etc.), and export to collectors (OTLP, console).

For the Python logging config, the `LOG_LEVEL` vs `OTEL_LOG_LEVEL` distinction,
and the `opentelemetry-instrument` run command, see
[python-otel.md](python-otel.md).

## Alerting

### Define SLIs and SLOs

```yaml
# Service Level Indicators
- API availability: % successful requests
- API latency: p95 response time
- Error rate: % failed requests

# Service Level Objectives
- 99.9% availability (< 0.1% error rate)
- p95 latency < 200ms
- p99 latency < 500ms
```

### Alert Best Practices

- Alert on **symptoms**, not causes (user impact, not disk space)
- Include context (affected service, time range, severity)
- Avoid alert fatigue (tune thresholds, use aggregation)
- Define clear escalation paths
- Include runbooks in alert descriptions

## Performance Considerations

- Use sampling for high-volume traces
- Batch exports to reduce overhead
- Use async exporters
- Monitor observability overhead itself
