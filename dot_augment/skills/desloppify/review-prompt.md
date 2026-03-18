# Desloppify Subjective Review

You are performing a holistic code quality review for desloppify integration.

## Context

- Repository:
  {{REPO_PATH}}
- Query file:
  {{QUERY_JSON_PATH}}

## Your Task

1. Run `uvx desloppify review --prepare` if query.json does not exist
2. Read the query.json file to get:
   - Dimension definitions
   - Language-specific guidance
   - Files to review
3. Perform holistic review (see process below)
4. Output findings.json
5. Run `uvx desloppify review --import findings.json`
6. Report summary

## Review Process

### Phase 1: Structural Overview

Before scoring any dimension:

1. List the directory structure (`view .
   type=directory`)
2. Identify key modules/components
3. Note patterns you observe:
   - Naming conventions used
   - Error handling approaches
   - Abstraction patterns
   - Code organization style
4. Form initial impressions

### Phase 2: Dimension Assessment

For each of the 12 dimensions, provide:

- **Score (0-100)**:
  Be calibrated.
  95+ is genuinely excellent.
- **Evidence**:
  Specific observations justifying the score
- **Findings**:
  For scores below 100, specific issues with file references

#### Dimension Definitions

| Dimension | What to Assess |
|-----------|----------------|
| high_elegance | Architecture patterns, overall design coherence |
| mid_elegance | Module and class-level design quality |
| low_elegance | Function and method-level craftsmanship |
| contracts | API clarity, interface definitions, boundary design |
| type_safety | Type hint coverage, type correctness, inference |
| design_coherence | Consistency of design decisions across codebase |
| abstraction_fit | Right level of abstraction, not over/under-engineered |
| logic_clarity | Readability, intent expression, self-documenting code |
| structure_nav | Navigability, discoverability, organization |
| error_consistency | Error handling patterns, consistency |
| naming_quality | Naming conventions, clarity, consistency |
| ai_generated_debt | Signs of vibe coding slop, copy-paste patterns |

## Output Format

Create `findings.json` with this exact schema:

```json
{
  "assessments": {
    "high_elegance": <score>,
    "mid_elegance": <score>,
    "low_elegance": <score>,
    "contracts": <score>,
    "type_safety": <score>,
    "design_coherence": <score>,
    "abstraction_fit": <score>,
    "logic_clarity": <score>,
    "structure_nav": <score>,
    "error_consistency": <score>,
    "naming_quality": <score>,
    "ai_generated_debt": <score>
  },
  "findings": [
    {
      "dimension": "<dimension_name>",
      "identifier": "<unique-kebab-case-id>",
      "summary": "<one line description>",
      "related_files": ["<file1>", "<file2>"],
      "evidence": "<specific observation>",
      "suggestion": "<how to fix>",
      "confidence": "high|medium|low"
    }
  ],
  "dimension_notes": {
    "<dimension>": {
      "evidence": "<overall observations for this dimension>"
    }
  }
}
```

## Rules

1. **Scores require evidence**:
   Any score below 100 must have findings
2. **Multiple findings for low scores**:
   Scores below 95 need multiple findings
3. **Be specific**:
   Reference actual files, functions, patterns
4. **Be calibrated**:
   Do not grade inflate.
   80 is acceptable.
   95+ is excellent.
5. **Cross-cutting insights**:
   Note patterns that span multiple files

## After Review

1. Save findings.json to repository root
2. Run:
   `uvx desloppify review --import findings.json`
3. Report:
   "Review complete.
   Imported N findings across M dimensions."
4. Show:
   Score summary and top 3 priority findings

---

## Deep Review Mode (Parallel Subagents)

For `/deslop deep`, use parallel subagents to review dimensions in batches.

## Subagent Dispatch Pattern

Dispatch 4-5 subagents in parallel, each handling a group of dimensions:

```python
# Group 1: Architecture dimensions
(
    sub
    - agent
    - explore(
        name="deep-review-arch",
        instruction="""
You are a blind code reviewer for desloppify. Review the <lang> codebase at
<repo_path> for these dimensions:

1. **cross_module_architecture** - Dependency direction, cycles, hub modules
2. **high_level_elegance** - Clear decomposition, domain-aligned structure
3. **convention_outlier** - Naming drift, style islands
4. **error_consistency** - Consistent strategies, preserved context
5. **naming_quality** - Intent-communicating names

Key files to examine: <list files with known issues>

For each dimension, provide:
1. Score (0-100)
2. 2-3 specific code evidence observations
3. List of issues found (dimension, identifier, summary, related_files, evidence, suggestion)
""",
    )
)
```

## Issue Requirements

**CRITICAL**:
Every dimension scored below 85 MUST have at least one issue.

Issues must include ALL required fields:

```json
{
  "dimension": "<dimension>",
  "identifier": "snake_case_short_id",
  "summary": "one-line defect summary",
  "related_files": ["relative/path.py"],
  "evidence": ["specific code observation"],
  "suggestion": "concrete fix recommendation",
  "confidence": "high|medium|low",
  "impact_scope": "local|module|subsystem|codebase",
  "fix_scope": "single_edit|multi_file_refactor|architectural_change"
}
```

## Compiling Results

After all subagents complete:

1. Extract assessments (scores) from each subagent
2. Extract dimension_notes from each subagent
3. Collect all issues into single array
4. Verify session.id and session.token from template
5. Write to review_result.json
6. Submit:
   `uvx desloppify --lang <lang> review --import <file> --scan-after-import`

## Example Subagent Groups

| Group | Dimensions | Focus |
|-------|------------|-------|
| arch | cross_module, high_level, convention, error, naming | Structure |
| design | abstraction, dependency, low_level, mid_level, auth | Quality |
| impl | package_org, init_coupling, design_coherence, contract, logic | Design |
| quality | type_safety, ai_debt, test_strategy, api_surface, incomplete | Debt |

## Multi-Language Support

For projects with multiple languages (Python + Rust):

```bash
# Run in parallel
uvx desloppify --lang python review --external-start ...
uvx desloppify --lang rust review --external-start ...

# Each generates its own session
# Submit separately after reviews complete
```
