---
name: ml-development
description: Use when working with ML systems - model lifecycle, authorization, and pointers to specialized ML skills for agents, clustering, and anomaly detection
---

# ML Development

Hub for machine learning development patterns and specialized skills.

## Specialized Skills

For specific ML domains, use the dedicated skills:

| Domain | Skill | Use Case |
|--------|-------|----------|
| **Supervised Learning** | | |
| Regression | `superpowers:regression-modeling` | Linear, Ridge, XGBoost for continuous targets |
| Classification | `superpowers:classification-modeling` | Binary/multiclass, imbalanced data |
| **Unsupervised Learning** | | |
| Clustering | `superpowers:clustering-analysis` | K-Means, DBSCAN, HDBSCAN |
| Topic Modeling | `superpowers:topic-modeling-bertopic` | BERTopic, document clustering |
| Dimensionality | `superpowers:dimensionality-reduction` | PCA, UMAP, t-SNE, feature selection |
| **Deep Learning** | | |
| PyTorch | `superpowers:pytorch-deep-learning` | Neural networks, training loops, GPU |
| NLP | `superpowers:nlp-text-processing` | Embeddings, classification, NER |
| **Probabilistic** | | |
| Bayesian | `superpowers:probabilistic-modeling` | Pyro, uncertainty, A/B testing |
| **Formal Methods** | | |
| Distributed Systems | `superpowers:formal-methods-distributed` | FizzBee, TLA+, Quint, consensus, safety |
| **Agentic AI** | | |
| Agent Design | `superpowers:agentic-ai-design` | Tools, planning, memory systems |
| Multi-Agent | `superpowers:multi-agent-patterns` | Orchestration, delegation, debate |
| Agent Tools | `superpowers:agentic-tools` | Tool schemas, sandboxing, composition |
| MCP Servers | `superpowers:mcp-server-development` | Creating MCP tool servers |
| AI Patterns | `superpowers:ai-design-patterns` | RAG, caching, fallbacks, prompts |
| **Operations** | | |
| Testing | `superpowers:ai-testing-patterns` | Model validation, agent testing |
| Monitoring | `superpowers:ai-monitoring` | Drift detection, metrics, alerting |
| Pipelines | `superpowers:argo-workflows-hera` | Workflow orchestration, scheduling |

## When to Use This Skill

Use this general skill for:

- Model lifecycle and versioning
- Authorization requirements
- Testing patterns that apply across ML domains
- Performance and resource management

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
