---
name: augment-skillers
description: Use when mining session transcripts for automation opportunities - extracts patterns, applies evidence thresholds, recommends skills/hooks/agents
---

# Augment Skillers

Mine Augment session transcripts for workflow patterns and suggest automation.

## When to Use

- User says "analyze my sessions" or "find automation opportunities"
- User says "what patterns do you see in my work"
- User says "recommend skills to create"
- Periodically (weekly) for workflow optimization

## Commands

| Command | Description |
|---------|-------------|
| `skillers show` | Show status, session stats, and knowledge themes |
| `skillers compact [--days=N]` | Analyze transcripts, extract patterns |
| `skillers recommend` | Suggest skills, hooks, agents based on evidence |

## Workflow

1. Load sessions via auglog infrastructure
2. Extract observations (pain, repeat, task, wish, workflow)
3. Apply weighted knowledge formula
4. Filter by evidence thresholds
5. Check ecosystem for existing coverage
6. Rank and recommend primitives

## Evidence Thresholds

Minimum bar before suggesting automation:
- 5+ total occurrences
- 3+ distinct sessions
- Weight >= 0.2

