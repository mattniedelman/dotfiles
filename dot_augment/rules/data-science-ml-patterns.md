---
type: agent_requested
priority: STANDARD
description: Data science and machine learning specific coding patterns and best practices
last_updated: 2025-01-26
---

# Data Science and ML Patterns

## ⚠️ Model and Data Pipeline Operation Authorization ⚠️

### Model Training and Deployment

**Operations requiring explicit permission:**

- Training or retraining models
- Deploying models to production
- Modifying production data pipelines
- Changing model hyperparameters in production
- Deleting or archiving models

**Before training models:**

```text
I will train a model with the following configuration:

Model type: [type]
Training data: [source, size]
Estimated time: [duration]
Estimated cost: [if applicable]

Proceed? (yes/no)
```

**Before deploying models:**

```text
⚠️  MODEL DEPLOYMENT

Model: [name/version]
Target environment: [dev/staging/production]

Validation results:
- [metrics]

This will replace: [current model if applicable]

For production deployments, have you:
- Validated model performance? (yes/no)
- Tested on staging? (yes/no)
- Prepared rollback plan? (yes/no)

Proceed? (yes/no)
```

### Data Pipeline Modifications

**Never modify production pipelines without explicit permission**

**Before modifying data pipelines:**

```text
I will modify the data pipeline:

Pipeline: [name]
Environment: [dev/staging/production]
Changes:
- [specific changes]

Impact:
- [affected downstream systems]
- [data processing changes]

Proceed? (yes/no)
```

---

## Model Development and Training

### Model Lifecycle Management

- **Rule**:
  Implement proper model versioning and lifecycle management
- **Implementation**:
  - Use consistent model serialization formats (pickle, joblib, etc.)
  - Implement model versioning with clear metadata
  - Separate model training from model serving code
  - Include model validation and testing in the development process

### Data Pipeline Design

- **Rule**:
  Design robust, testable data pipelines
- **Implementation**:
  - Use modern data processing libraries (Polars, DuckDB) for performance
  - Implement data validation at pipeline boundaries
  - Design pipelines to handle missing or malformed data gracefully
  - Use consistent data formats and schemas throughout pipelines

### Experiment Tracking

- **Rule**:
  Track experiments and model performance systematically
- **Implementation**:
  - Log model parameters, metrics, and artifacts
  - Use consistent evaluation metrics across experiments
  - Document model assumptions and limitations
  - Maintain reproducible experiment environments

## Clustering and Topic Modeling

### BERTopic Integration Patterns

- **Rule**:
  Follow established patterns for topic modeling workflows
- **Rationale**:
  Based on observed workstation clustering implementation patterns
- **Implementation**:
  - Separate model training from inference/prediction
  - Use consistent document preprocessing pipelines
  - Implement proper dimensionality handling for embeddings
  - Design for incremental model updates and merging

### Clustering Evaluation

- **Rule**:
  Implement comprehensive clustering evaluation metrics
- **Implementation**:
  - Use multiple evaluation metrics (silhouette score, coherence, etc.)
  - Implement visualization tools for cluster analysis
  - Provide interpretable cluster summaries and naming
  - Track clustering performance over time

### Data Transformation Consistency

- **Rule**:
  Maintain consistent data transformation patterns
- **Implementation**:
  - Use the same transformation pipeline for training and inference
  - Handle sparse and dense matrices consistently
  - Implement proper dimensionality reduction techniques
  - Validate transformation outputs at each step

## Performance and Scalability

### Memory Management

- **Rule**:
  Implement efficient memory usage patterns for large datasets
- **Implementation**:
  - Use streaming processing for large datasets
  - Implement proper garbage collection for long-running processes
  - Monitor memory usage and implement appropriate limits
  - Use memory-efficient data structures (sparse matrices, etc.)

### Computational Efficiency

- **Rule**:
  Optimize computational performance without sacrificing code clarity
- **Implementation**:
  - Profile code to identify actual bottlenecks
  - Use vectorized operations where possible
  - Implement parallel processing for independent operations
  - Cache expensive computations appropriately

### Resource Management

- **Rule**:
  Implement proper resource management for ML workloads
- **Implementation**:
  - Use context managers for file and database connections
  - Implement proper cleanup for temporary files and resources
  - Monitor and limit resource usage in production environments
  - Use appropriate batch sizes for processing

## Testing ML Code

### Model Testing Strategies

- **Rule**:
  Implement comprehensive testing for ML models and pipelines
- **Implementation**:
  - Test data preprocessing and transformation logic
  - Implement smoke tests for model training and inference
  - Test model serialization and deserialization
  - Validate model outputs against expected ranges and distributions

### Data Quality Testing

- **Rule**:
  Implement automated data quality checks
- **Implementation**:
  - Validate data schemas and types
  - Check for data completeness and consistency
  - Implement statistical tests for data distribution changes
  - Test edge cases and boundary conditions

### Integration Testing

- **Rule**:
  Test ML components in realistic integration scenarios
- **Implementation**:
  - Test end-to-end pipelines with realistic data volumes
  - Validate model performance under different data conditions
  - Test model serving and API integration
  - Implement regression tests for model performance

## Documentation and Reproducibility

### Model Documentation

- **Rule**:
  Document models, algorithms, and design decisions thoroughly
- **Implementation**:
  - Document model architecture and hyperparameters
  - Explain feature engineering and data preprocessing steps
  - Include performance metrics and evaluation results
  - Document known limitations and assumptions

### Code Documentation

- **Rule**:
  Provide clear documentation for complex ML algorithms
- **Implementation**:
  - Explain mathematical concepts and algorithms in comments
  - Document data flow and transformation steps
  - Include examples of expected inputs and outputs
  - Reference relevant papers or resources for complex algorithms

### Reproducibility

- **Rule**:
  Ensure ML experiments and models are reproducible
- **Implementation**:
  - Set random seeds for reproducible results
  - Pin dependency versions in requirements files
  - Document environment setup and configuration
  - Use containerization for consistent execution environments
