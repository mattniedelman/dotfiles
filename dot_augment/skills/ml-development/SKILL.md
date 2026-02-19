---
name: ml-development
description: Machine learning and data science development patterns - model lifecycle, pipelines, BERTopic, testing, and authorization
---

# ML Development

Guide for machine learning and data science development patterns.

## When to Use

Use this skill when:

- Training or deploying ML models
- Building data pipelines
- Working with topic modeling (BERTopic)
- Testing ML code
- Managing model lifecycle

## Authorization Requirements

**Operations requiring EXPLICIT permission:**

- Training/retraining models
- Deploying models to production
- Modifying production data pipelines
- Changing production hyperparameters
- Deleting or archiving models

### Before Training Models

```text
I will train a model:
- Model type: [type]
- Training data: [source, size]
- Estimated time: [duration]
- Estimated cost: [if applicable]

Proceed? (yes/no)
```

### Before Deploying Models

```text
⚠️ MODEL DEPLOYMENT

Model: [name/version]
Target: [dev/staging/production]

Validation: [metrics]
Replaces: [current model if applicable]

For production:
- [ ] Validated performance?
- [ ] Tested on staging?
- [ ] Rollback plan?

Proceed? (yes/no)
```

## Model Lifecycle

1. **Versioning**:
   Consistent serialization (pickle, joblib), clear metadata
2. **Separation**:
   Training code separate from serving code
3. **Validation**:
   Model testing in development process
4. **Tracking**:
   Log parameters, metrics, artifacts per experiment

## Data Pipeline Design

- Use Polars or DuckDB for performance
- Validate data at pipeline boundaries
- Handle missing/malformed data gracefully
- Maintain consistent schemas throughout

## BERTopic Patterns

Based on observed workstation clustering implementations:

- Separate training from inference/prediction
- Consistent document preprocessing
- Proper dimensionality handling for embeddings
- Design for incremental updates and merging

### Clustering Evaluation

- Multiple metrics (silhouette, coherence)
- Visualization tools for analysis
- Interpretable cluster summaries
- Track performance over time

## Testing ML Code

### Model Tests

- Test preprocessing and transformation logic
- Smoke tests for training and inference
- Test serialization/deserialization
- Validate outputs against expected ranges

### Data Quality Tests

- Validate schemas and types
- Check completeness and consistency
- Statistical tests for distribution changes
- Edge cases and boundary conditions

### Integration Tests

- End-to-end with realistic data volumes
- Performance under different conditions
- Model serving and API integration
- Regression tests for model performance

## Performance Patterns

### Memory Management

- Streaming for large datasets
- Proper garbage collection
- Monitor and limit memory usage
- Memory-efficient structures (sparse matrices)

### Computational Efficiency

- Profile to find actual bottlenecks
- Vectorized operations
- Parallel processing for independent ops
- Cache expensive computations

### Resource Management

- Context managers for connections
- Cleanup temporary files
- Monitor production resource usage
- Appropriate batch sizes

## Documentation

### Model Documentation

- Architecture and hyperparameters
- Feature engineering steps
- Performance metrics and results
- Known limitations and assumptions

### Reproducibility

- Set random seeds
- Pin dependency versions
- Document environment setup
- Use containerization
