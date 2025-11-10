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

## Structured Logging

**Use Structured Logging with Context:**
```python
import structlog

logger = structlog.get_logger()

# ✅ Correct - Structured with context
logger.info(
    "user_login",
    user_id=user.id,
    email=user.email,
    ip_address=request.remote_addr,
    user_agent=request.headers.get("User-Agent")
)

# ❌ Avoid - Unstructured string
logger.info(f"User {user.id} logged in from {request.remote_addr}")
```

**Log Levels:**
- `DEBUG`: Detailed diagnostic information
- `INFO`: General informational messages (user actions, system events)
- `WARNING`: Warning messages (degraded performance, using fallback)
- `ERROR`: Error messages (handled exceptions, failed operations)
- `CRITICAL`: Critical errors (system failures, data corruption)

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

## OpenTelemetry Integration

**Prefer OpenTelemetry for Observability:**
- Vendor-neutral standard for traces, metrics, and logs
- Single instrumentation for multiple backends
- Automatic instrumentation for common frameworks

**Setup OpenTelemetry:**
```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor

# Configure tracer
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

# Export to OTLP endpoint (Jaeger, Tempo, etc.)
otlp_exporter = OTLPSpanExporter(endpoint="http://localhost:4317")
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(otlp_exporter)
)

# Auto-instrument frameworks
FastAPIInstrumentor.instrument_app(app)
SQLAlchemyInstrumentor().instrument(engine=engine)
```

**Manual Tracing:**
```python
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

def process_order(order_id: str) -> Order:
    with tracer.start_as_current_span("process_order") as span:
        span.set_attribute("order.id", order_id)
        
        # Fetch order
        with tracer.start_as_current_span("fetch_order"):
            order = db.get_order(order_id)
            span.set_attribute("order.total", order.total)
        
        # Process payment
        with tracer.start_as_current_span("process_payment"):
            payment_result = payment_service.charge(order)
            span.set_attribute("payment.status", payment_result.status)
        
        if payment_result.success:
            span.set_attribute("order.status", "completed")
        else:
            span.set_attribute("order.status", "failed")
            span.record_exception(payment_result.error)
        
        return order
```

**Span Attributes:**
```python
# Add relevant attributes to spans
span.set_attribute("user.id", user_id)
span.set_attribute("http.method", request.method)
span.set_attribute("http.url", request.url)
span.set_attribute("db.statement", query)
span.set_attribute("error", True)  # For errors
```

## Metrics with OpenTelemetry

**Define Metrics:**
```python
from opentelemetry import metrics
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter

# Configure metrics
metric_reader = PeriodicExportingMetricReader(
    OTLPMetricExporter(endpoint="http://localhost:4317")
)
metrics.set_meter_provider(MeterProvider(metric_readers=[metric_reader]))
meter = metrics.get_meter(__name__)

# Create metrics
request_counter = meter.create_counter(
    "http.server.requests",
    description="Total HTTP requests",
    unit="1"
)

request_duration = meter.create_histogram(
    "http.server.duration",
    description="HTTP request duration",
    unit="ms"
)

active_users = meter.create_up_down_counter(
    "app.users.active",
    description="Number of active users",
    unit="1"
)
```

**Record Metrics:**
```python
# Counter
request_counter.add(1, {"method": "GET", "endpoint": "/api/users", "status": 200})

# Histogram
request_duration.record(
    duration_ms,
    {"method": "GET", "endpoint": "/api/users"}
)

# Gauge (via UpDownCounter)
active_users.add(1)  # User logged in
active_users.add(-1)  # User logged out
```

**Key Metrics to Track:**
- Request rate (requests per second)
- Request duration (latency percentiles: p50, p95, p99)
- Error rate (errors per second, error percentage)
- Active connections/users
- Database query duration
- Cache hit/miss rate
- Queue depth and processing time

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

## Distributed Tracing

**Trace Context Propagation:**
```python
# Automatically propagated by OpenTelemetry instrumentation
# Manual propagation for custom clients:
from opentelemetry.propagate import inject

headers = {}
inject(headers)  # Injects trace context into headers

response = requests.get(
    "https://api.example.com/data",
    headers=headers  # Propagates trace context
)
```

**Trace Sampling:**
```python
from opentelemetry.sdk.trace.sampling import TraceIdRatioBased

# Sample 10% of traces
sampler = TraceIdRatioBased(0.1)

trace.set_tracer_provider(
    TracerProvider(sampler=sampler)
)
```

**Trace Analysis:**
- Identify slow operations (database queries, external API calls)
- Find bottlenecks in request processing
- Understand service dependencies
- Debug distributed system issues

## Error Tracking

**Integrate Error Tracking:**
```python
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration

sentry_sdk.init(
    dsn="https://your-dsn@sentry.io/project",
    integrations=[FastApiIntegration()],
    traces_sample_rate=0.1,
    environment="production"
)

# Errors are automatically captured
# Add context manually:
with sentry_sdk.configure_scope() as scope:
    scope.set_user({"id": user.id, "email": user.email})
    scope.set_tag("feature", "checkout")
    scope.set_context("order", {"id": order.id, "total": order.total})
```

**Error Context:**
- User information (ID, email, not sensitive data)
- Request information (URL, method, headers)
- Application state (feature flags, configuration)
- Custom tags for filtering and grouping

## Observability Best Practices

**Three Pillars of Observability:**
1. **Logs**: What happened (events, errors, debug info)
2. **Metrics**: How much/how many (counters, gauges, histograms)
3. **Traces**: Where time was spent (request flow, dependencies)

**Correlation:**
- Use consistent identifiers (request_id, user_id, trace_id)
- Link logs to traces via trace context
- Include trace_id in log messages
- Use OpenTelemetry for unified correlation

**Performance Considerations:**
- Use sampling for high-volume traces
- Batch exports to reduce overhead
- Use async exporters
- Monitor observability overhead itself

**Observability Stack:**
- **Traces**: Jaeger, Tempo, Zipkin
- **Metrics**: Prometheus, Grafana
- **Logs**: Loki, Elasticsearch
- **All-in-one**: Grafana Cloud, Datadog, New Relic
- **OpenTelemetry Collector**: Central collection and routing

**Development vs Production:**
- Development: Verbose logging, 100% trace sampling
- Production: Structured logging, sampled tracing, aggregated metrics
- Use environment-specific configuration
- Test observability in staging environments


