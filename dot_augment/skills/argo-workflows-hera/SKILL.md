---
name: argo-workflows-hera
description: Use when orchestrating ML pipelines with Argo Workflows via Hera Python SDK - workflow definition, DAGs, cron scheduling, and Kubernetes integration patterns
---

# Argo Workflows with Hera

## Overview

Hera provides Python-native workflow definitions for Argo Workflows, enabling
ML pipeline orchestration with type safety and IDE support.

**Core principle:** Workflows should be reproducible and idempotent. Design for
retry and failure recovery from any step.

## When to Use

- Orchestrating multi-step ML pipelines
- Scheduling recurring ML jobs (CronWorkflows)
- Processing data in parallel
- Triggering workflows via API

## Workflow Types

| Type | Use Case | Trigger |
|------|----------|---------|
| Workflow | One-time execution | API call, manual |
| CronWorkflow | Scheduled recurring | Cron expression |

## Basic Workflow Structure

```python
from hera.workflows import (
    Workflow,
    Steps,
    script,
    Parameter,
)

@script(image="python:3.12-slim")
def process_data(input_path: str) -> str:
    """Process input data and return output path."""
    import pandas as pd
    df = pd.read_parquet(input_path)
    output_path = input_path.replace("input", "output")
    df.to_parquet(output_path)
    return output_path

@script(image="python:3.12-slim")
def train_model(data_path: str) -> str:
    """Train model on processed data."""
    ...
    return model_path

with Workflow(
    generate_name="ml-pipeline-",
    entrypoint="pipeline",
    arguments=[Parameter(name="input_path")],
) as w:
    with Steps(name="pipeline"):
        processed = process_data(
            arguments={"input_path": "{{workflow.parameters.input_path}}"}
        )
        train_model(arguments={"data_path": processed.result})
```

## TTL and Cleanup

### TTL Strategy (Required)

```python
from hera.workflows import TTLStrategy

workflow = Workflow(
    generate_name="ddi-pipeline-",
    ttl_strategy=TTLStrategy(
        seconds_after_completion=172800,  # 2 days
        seconds_after_failure=172800,
        seconds_after_success=86400,      # 1 day for success
    ),
)
```

### Why TTL Matters

- Argo stores workflow state in etcd
- Without TTL, workflows accumulate indefinitely
- etcd has storage limits that cause cluster issues
- Production standard: 2 days retention

## CronWorkflows

### Daily ML Update Pattern

```python
from hera.workflows import CronWorkflow

with CronWorkflow(
    name="daily-model-update",
    schedule="0 6 * * *",  # 6 AM daily
    timezone="America/New_York",
    concurrency_policy="Forbid",  # Skip if previous still running
    starting_deadline_seconds=3600,  # 1 hour grace period
    ttl_strategy=TTLStrategy(seconds_after_completion=172800),
) as cron:
    with Steps(name="update"):
        extract_new_data()
        update_model()
```

### Concurrency Policies

| Policy | Behavior |
|--------|----------|
| Allow | Run concurrent instances |
| Forbid | Skip if previous running |
| Replace | Cancel previous, start new |

## DAG Workflows

### Parallel Processing

```python
from hera.workflows import DAG, Task

with Workflow(generate_name="parallel-processing-") as w:
    with DAG(name="process-clients"):
        # Fan out to process multiple clients
        clients = ["client_a", "client_b", "client_c"]
        tasks = [
            Task(
                name=f"process-{client}",
                template=process_client,
                arguments={"client_id": client},
            )
            for client in clients
        ]

        # Fan in to aggregate results
        aggregate = Task(
            name="aggregate",
            template=aggregate_results,
            dependencies=[t.name for t in tasks],
        )
```

## API Integration

### Submitting Workflows

```python
from hera.workflows import Workflow
from hera.shared import global_config

# Configure Hera to connect to Argo server
global_config.host = "https://argo-workflows.argo.svc.cluster.local:2746"
global_config.verify_ssl = False

def submit_workflow(client_id: str, dates: list[str]) -> str:
    """Submit workflow and return workflow name."""
    workflow = create_detection_workflow(client_id, dates)
    submitted = workflow.create()
    return submitted.metadata.name
```

### FastAPI Endpoint Pattern

```python
from fastapi import HTTPException

@app.post("/job/{client_id}")
async def submit_job(
    client_id: str,
    request: JobRequest,
) -> JobResponse:
    try:
        workflow_name = submit_workflow(client_id, request.dates)
        return JobResponse(
            workflow_name=workflow_name,
            status="submitted",
        )
    except Exception as e:
        logger.error("workflow_submission_failed", error=str(e))
        raise HTTPException(500, f"Failed to submit workflow: {e}")

@app.get("/job/{client_id}/{workflow_name}")
async def get_job_status(
    client_id: str,
    workflow_name: str,
) -> JobStatusResponse:
    status = get_workflow_status(workflow_name)
    return JobStatusResponse(
        workflow_name=workflow_name,
        phase=status.phase,
        started_at=status.started_at,
        finished_at=status.finished_at,
    )
```

## Kubernetes Integration

### Service Account and IRSA

```python
from hera.workflows import Workflow

workflow = Workflow(
    generate_name="ml-pipeline-",
    service_account_name="ml-workflow-sa",  # Has IRSA for S3 access
    namespace="ml-workflows",
)
```

### Resource Requests

```python
from hera.workflows import Resources, script

@script(
    image="ghcr.io/org/ml-image:latest",
    resources=Resources(
        cpu_request="500m",
        memory_request="1Gi",
        cpu_limit="2",
        memory_limit="4Gi",
    ),
)
def train_model(data_path: str):
    ...
```

## Webhook Callbacks

### Notify on Completion

```python
@script()
def send_webhook(result_path: str, webhook_url: str):
    """Send completion notification."""
    import httpx
    response = httpx.post(
        webhook_url,
        json={
            "status": "completed",
            "result_path": result_path,
            "timestamp": datetime.now().isoformat(),
        },
    )
    response.raise_for_status()

with Workflow(generate_name="pipeline-") as w:
    with Steps(name="pipeline"):
        result = run_pipeline()
        send_webhook(
            arguments={
                "result_path": result.result,
                "webhook_url": "{{workflow.parameters.webhook_url}}",
            }
        )
```

## Testing Workflows

### Unit Test Script Functions

```python
def test_process_data_transforms_correctly(tmp_path: Path):
    # Arrange
    input_df = pd.DataFrame({"a": [1, 2, 3]})
    input_path = tmp_path / "input.parquet"
    input_df.to_parquet(input_path)

    # Act - call the script function directly
    output_path = process_data.func(str(input_path))

    # Assert
    output_df = pd.read_parquet(output_path)
    assert len(output_df) == 3
```

### Integration Test with MinIO

```python
@pytest.fixture
def minio_container():
    with MinioContainer() as minio:
        yield minio

def test_workflow_end_to_end(minio_container):
    # Upload test data to MinIO
    # Submit workflow
    # Wait for completion
    # Verify results in MinIO
    ...
```

