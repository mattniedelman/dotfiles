---
name: desloppify
description: Use when assessing holistic code quality, checking health score, running subjective review, or when working on PRs and CI suggests quality check
---

# Desloppify - Code Quality Assessment

## Overview

Assess codebase quality using desloppify's mechanical scan and subjective
review.
Uses `uvx desloppify` for execution (no project dependency needed).

**Commands:**

- `/deslop` - Scan + status + suggest review if warranted
- `/deslop review` - Force full subjective review (dispatches subagent)
- `/deslop deep` - Deep file-level reviews using parallel subagents

## Quick Reference

```bash
# Mechanical scan (fast, ~30s)
uvx desloppify scan --path .

# Check current status
uvx desloppify status

# Prepare review packet
uvx desloppify review --prepare

# Import findings after review
uvx desloppify review --import findings.json

# Show next priority finding
uvx desloppify next

# Resolve a finding
uvx desloppify resolve fixed 'what changed' \
 --attest 'I have actually [CHANGE] and I am not gaming the score' <id >--note
```

## /deslop Command Flow

```text
1. Check scan recency:
   - Read .desloppify/state.json for last_scan
   - Compare to: git log --format=%cI -1 (latest commit)
   
2. If commits since last scan:
   - Run: uvx desloppify scan --path .
   
3. Parse scan output for:
   - Current scores (overall, strict)
   - Stale subjective dimensions
   - Open T3/T4 findings count
   
4. Suggest review if:
   - Subjective dimensions marked stale
   - Strict score dropped >5% since last scan
   - T3/T4 findings > 5 open

5. Display status summary

6. Automatically proceed (see Post-Scan Behavior)
```

## Post-Scan Behavior

After displaying the status summary, automatically proceed based on findings:

**If findings exist (T3/T4 > 0):**

1. Show findings summary (count by severity/category)
2. Run `uvx desloppify next` to get first finding
3. Start fixing it immediately
4. After fix, ask:
   "Continue to next finding?
   (y/n)"
5. Repeat until all findings addressed or user stops

**If no findings:**

1. Announce "No mechanical findings - starting subjective review"
2. Execute `/deslop review` flow (dispatch subagent)

**Finding loop format:**

```text
┌─────────────────────────────────────────┐
│ Finding 1/N: [title]                    │
│ File: src/foo.py:42                     │
│ Issue: [description]                    │
├─────────────────────────────────────────┤
│ [Implement fix]                         │
├─────────────────────────────────────────┤
│ Fixed. Resolving...                     │
│ uvx desloppify resolve fixed '...' --id │
│                                         │
│ Continue to next finding? (y/n)         │
└─────────────────────────────────────────┘
```

**Exit points:**

- User says "n" or "stop" or "enough" - end loop, show remaining count
- All findings resolved - proceed to subjective review if dimensions stale
- User explicitly asks for something else - honor that request

## /deslop review Command Flow

Dispatches `sub-agent-code-reviewer` with desloppify review instructions.

```text
1. Run: uvx desloppify review --prepare
   → Creates .desloppify/query.json

2. Extract from query.json:
   - dimensions[] (canonical definitions)
   - language_guidance (language-specific hints)
   - files to review

3. Subagent performs holistic review:
   Phase 1: Structural overview (skim all files)
   Phase 2: Score each dimension with evidence

4. Subagent outputs findings.json

5. Run: uvx desloppify review --import findings.json

6. Return summary to main conversation
```

## /deslop deep Command Flow - Deep Subjective Reviews

For thorough file-level reviews using parallel subagents.
Handles both Python and Rust (or any language desloppify supports).

```text
1. Prepare external review session:
   uvx desloppify --lang <lang> review --prepare --force-review-rerun
   uvx desloppify --lang <lang> review --external-start --external-runner claude

2. Read session info from output:
   - Session ID: ext_YYYYMMDD_HHMMSS_<hash>
   - Blind packet: .desloppify/review_packet_blind.json
   - Template: .desloppify/external_review_sessions/<session>/review_result.template.json
   - Output target: .desloppify/external_review_sessions/<session>/review_result.json

3. Dispatch parallel subagents (4-5 groups of dimensions):
   - Group 1: cross_module_architecture, high_level_elegance, convention_outlier, error_consistency, naming_quality
   - Group 2: abstraction_fitness, dependency_health, low_level_elegance, mid_level_elegance, authorization_consistency
   - Group 3: package_organization, initialization_coupling, design_coherence, contract_coherence, logic_clarity
   - Group 4: type_safety, ai_generated_debt, test_strategy, api_surface_coherence, incomplete_migration

4. Each subagent reviews its dimensions and returns:
   - Score (0-100) per dimension
   - Evidence observations (2-3 per dimension)
   - Issues list with required fields

5. Compile results into review_result.json (see schema below)

6. Submit:
   uvx desloppify --lang <lang> review --import <session>/review_result.json --scan-after-import
```

### Deep Review JSON Schema

**CRITICAL**:
Every dimension scored below 85 MUST have at least one issue.

```json
{
  "session": {
    "id": "<preserve from template>",
    "token": "<preserve from template>"
  },
  "assessments": {
    "<dimension>": <0-100 with one decimal>
  },
  "dimension_notes": {
    "<dimension>": {
      "evidence": ["specific code observations"],
      "impact_scope": "local|module|subsystem|codebase",
      "fix_scope": "single_edit|multi_file_refactor|architectural_change",
      "confidence": "high|medium|low"
    }
  },
  "issues": [{
    "dimension": "<dimension>",
    "identifier": "short_snake_case_id",
    "summary": "one-line defect summary",
    "related_files": ["relative/path.py"],
    "evidence": ["specific code observation"],
    "suggestion": "concrete fix recommendation",
    "confidence": "high|medium|low",
    "impact_scope": "local|module|subsystem|codebase",
    "fix_scope": "single_edit|multi_file_refactor|architectural_change"
  }]
}
```

### Subagent Prompt Template for Deep Review

Each subagent receives:

```text
You are a blind code reviewer for desloppify. Review the <lang> codebase at
<repo_path> for these dimensions:

1. **<dimension_1>** - <description>
2. **<dimension_2>** - <description>
...

Key files to examine:
- <file1> (<known issue>)
- <file2> (<known issue>)
...

For each dimension, provide:
1. Score (0-100)
2. 2-3 specific code evidence observations
3. List of issues found (dimension, identifier, summary, related_files, evidence, suggestion)

Output as structured text that can be parsed.
```

### Import Fallback

If external submit fails with hash mismatch:

```bash
# Issues-only import (scores preserved from prior state)
uvx desloppify --lang --import --scan-after-import <lang >review <session >/review_result.json

# Manual override with attestation (updates scores)
uvx desloppify --lang --import --attest "Blind review completed without score awareness" <lang >review <file >--manual-override
```

## Subagent Instructions

Use the prompt template at:
`desloppify/review-prompt.md`

Pass to subagent:

- REPO_PATH:
  Current repository path
- QUERY_JSON_PATH:
  Path to .desloppify/query.json

## PR-Aware Trigger

When user mentions working on a PR:

1. Check if branch scanned recently (commits since last_scan)
2. Check CI status if mentioned
3. If unscanned + CI green:
   suggest `/deslop`

Example:

```text
User: "CI is passing now, ready to merge"
Agent: "Branch hasn't had a quality scan since 3 commits ago.
        Run /deslop before merging? (y/n)"
```

## The 20 Subjective Dimensions (Full Set)

Desloppify uses 20 dimensions for deep reviews.
Grouped by investigation batch:

| Dimension | Focus | What to Look For |
|-----------|-------|------------------|
| **Architecture** | | |
| cross_module_architecture | Boundaries | Cycles, hub modules, boundary violations |
| high_level_elegance | Decomposition | Domain alignment, ownership clarity |
| package_organization | Directory layout | Navigability, placement matches ownership |
| **Module Design** | | |
| mid_level_elegance | Integration seams | Handoffs, boundary data translation |
| abstraction_fitness | Right level | No pass-through wrappers, earned abstractions |
| design_coherence | Decisions | Focused functions, consistent patterns |
| **Implementation** | | |
| low_level_elegance | Function craft | Direct control flow, bounded mutations |
| logic_clarity | Correctness | No dead code, simplified expressions |
| naming_quality | Communication | Intent-revealing names, no generic verbs |
| **Error Handling** | | |
| error_consistency | Strategies | Consistent throw/return/Result, context preserved |
| contract_coherence | Promises | Return types match, docstrings accurate |
| **Type System** | | |
| type_safety | Annotations | All paths covered, no unsafe unwrap |
| **Dependencies** | | |
| dependency_health | Deps | No unused, no conflicts, no redundant libs |
| initialization_coupling | Boot order | No import-time I/O, no global singletons |
| **Patterns** | | |
| convention_outlier | Consistency | Style islands, naming drift |
| authorization_consistency | Auth | Permission patterns applied consistently |
| **Quality Debt** | | |
| ai_generated_debt | LLM slop | Restating comments, defensive overengineering |
| test_strategy | Coverage | Critical paths tested, no fragility |
| api_surface_coherence | API shape | Consistent params, clear error contracts |
| incomplete_migration | Tech debt | Old+new coexisting, stale shims |

## Error Handling

| Error | Response |
|-------|----------|
| uvx not found | "uvx required. Install: pip install uv" |
| No .desloppify/state.json | First run - scan will create it |
| Scan fails | Show error, suggest manual debug |
| Import validation fails | Show desloppify error, check schema |
| Hash mismatch on submit | Use fallback import (see Import Fallback section) |
| rerun blocked: open backlog | Use --force-review-rerun to bypass |

## Integration Points

- relates_to ::
  [[requesting-code-review]] - complementary quality checks
- relates_to ::
  [[finishing-a-development-branch]] - quality gate before merge
- relates_to ::
  [[verification-before-completion]] - evidence-based claims
- relates_to ::
  [[dispatching-parallel-agents]] - deep review uses parallel subagents
