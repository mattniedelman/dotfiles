---
type: agent_requested
description: Error handling patterns, structured logging, observability with OpenTelemetry, metrics, tracing, and monitoring best practices
---

# Error Handling and Observability

## Error Handling Principles

**Use Specific Exception Types:**

```python
# ✅ Correct - Specific exceptions
class UserNotFoundError(Exception):
    """Raised when user cannot be found."""
    pass

class InvalidCredentialsError(Exception):
    """Raised when authentication fails."""
    pass

def get_user(user_id: str) -> User:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise UserNotFoundError(f"User {user_id} not found")
    return user

# ❌ Avoid - Generic exceptions
def get_user(user_id: str) -> User:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise Exception("Error")  # Too generic
    return user
```

**Provide Context in Errors:**

```python
# ✅ Correct - Rich context
raise ValidationError(
    f"Invalid email format: {email}",
    field="email",
    value=email,
    user_id=user_id
)

# ❌ Avoid - No context
raise ValidationError("Invalid email")
```

**Error Recovery:**

```python
# ✅ Correct - Graceful degradation
def get_user_profile(user_id: str) -> UserProfile:
    try:
        profile = external_api.fetch_profile(user_id)
    except ExternalAPIError as e:
        logger.warning(f"External API failed, using cached data: {e}")
        profile = cache.get(f"profile:{user_id}")
        if not profile:
            raise UserProfileUnavailableError(f"Cannot fetch profile for {user_id}")
    return profile
```

**Log Levels:**

- `DEBUG`:
  Detailed diagnostic information
- `INFO`:
  General informational messages (user actions, system events)
- `WARNING`:
  Warning messages (degraded performance, using fallback)
- `ERROR`:
  Error messages (handled exceptions, failed operations)
- `CRITICAL`:
  Critical errors (system failures, data corruption)

**What to Log:**

```python
# ✅ Log these events
logger.info("user_created", user_id=user.id, email=user.email)
logger.warning("rate_limit_exceeded", user_id=user.id, endpoint="/api/data")
logger.error("database_connection_failed", error=str(e), retry_count=3)

# ❌ Never log sensitive data
logger.info(f"User logged in with password: {password}")  # NEVER
logger.debug(f"API key: {api_key}")  # NEVER
```

**Correlation IDs:**

```python
import uuid
from contextvars import ContextVar

request_id_var: ContextVar[str] = ContextVar("request_id")

@app.before_request
def set_request_id():
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
    request_id_var.set(request_id)
    structlog.contextvars.bind_contextvars(request_id=request_id)

# All logs in this request will include request_id
logger.info("processing_request", endpoint=request.path)
```

## Alerting and Monitoring

**Define SLIs and SLOs:**

```yaml
# Service Level Indicators (SLIs)
- API availability: % of successful requests
- API latency: p95 response time
- Error rate: % of failed requests

# Service Level Objectives (SLOs)
- 99.9% availability (< 0.1% error rate)
- p95 latency < 200ms
- p99 latency < 500ms
```

**Alert on SLO Violations:**

```python
# Example alert conditions
if error_rate > 1.0:  # > 1% errors
    alert("High error rate", severity="critical")

if p95_latency > 200:  # p95 > 200ms
    alert("High latency", severity="warning")

if availability < 99.9:  # < 99.9% uptime
    alert("Low availability", severity="critical")
```

**Alert Best Practices:**

- Alert on symptoms, not causes (user impact, not disk space)
- Include context in alerts (affected service, time range, severity)
- Avoid alert fatigue (tune thresholds, use aggregation)
- Define clear escalation paths
- Include runbooks in alert descriptions

## Observability Best Practices

**Three Pillars of Observability:**

1. **Logs**:
   What happened (events, errors, debug info)
2. **Metrics**:
   How much/how many (counters, gauges, histograms)
3. **Traces**:
   Where time was spent (request flow, dependencies)

**Correlation:**

- Use consistent identifiers (request_id, user_id, trace_id)
- Link logs to traces via trace context
- Include trace_id in log messages
- Use OpenTelemetry for unified correlation.
  Prefer auto-instrumentation as much as possible.

**Performance Considerations:**

- Use sampling for high-volume traces
- Batch exports to reduce overhead
- Use async exporters
- Monitor observability overhead itself
