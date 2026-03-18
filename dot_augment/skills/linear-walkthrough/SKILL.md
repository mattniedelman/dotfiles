---
name: linear-walkthrough
description: Use when understanding unfamiliar code or paying down cognitive debt - create structured walkthrough explaining how code works
---

# Linear Walkthrough

Generate a structured walkthrough of a codebase to understand how it works.

**Inspired by:** Simon Willison's pattern of having agents create walkthroughs
to understand vibe-coded or unfamiliar code - paying down "cognitive debt."

## Cognitive Debt

When you lose track of how code works, you take on **cognitive debt**:

- Can't confidently reason about the system
- Planning new features becomes harder
- Debugging is shooting in the dark

**Walkthroughs pay down this debt.**

## When to Use

- Code you didn't write (joining project, reviewing PR)
- Code you wrote but forgot (after weeks/months)
- Vibe-coded projects needing understanding
- Before making significant changes to unfamiliar area
- Onboarding to new codebase or subsystem

## Process

### 1. Identify Scope

What needs to be understood?

```text
# Whole project
"Create a walkthrough of this repository"

# Specific subsystem
"Walk through the authentication system"

# Single feature
"Explain how the search feature works"
```

### 2. Survey Entry Points

Find where execution starts:

```bash
# Find main entry points
find_symbol(name_path_pattern="main", include_info=True)
find_symbol(name_path_pattern="app", include_info=True)

# For web apps
get_symbols_overview(relative_path="src/routes", depth=1)
get_symbols_overview(relative_path="src/api", depth=1)
```

### 3. Trace Key Flows

Follow the critical paths:

```text
Request → Router → Handler → Service → Database → Response
```

### 4. Document with Real Code

**CRITICAL:** Use grep/sed/cat to include code snippets, never copy-paste.
This ensures accuracy and prevents hallucination.

```bash
# Include specific lines
sed -n '45,60p' src/auth/login.py

# Show function signature
grep -A5 "def authenticate" src/auth/service.py

# Find all handlers
grep -n "@app.route" src/routes/*.py
```

### 5. Save to Basic Memory

```python
write_note_basic - memory(
    title="Walkthrough: {Project Name}",
    content="[walkthrough content]",
    directory="knowledge/walkthroughs",
    tags=["walkthrough", "understanding", "{project}"],
)
```

## Walkthrough Structure

```markdown
---
title: Walkthrough: {Project/Subsystem}
type: walkthrough
tags:
  - walkthrough
  - understanding
  - {project-name}
source: code-analysis
confidence: high
observed: {YYYY-MM-DD}
---

# Walkthrough: {Project Name}

## Overview

[2-3 sentences: What does this code do? What problem does it solve?]

## Architecture

[High-level structure: main components and how they connect]

\`\`\`text
┌─────────┐     ┌─────────┐     ┌─────────┐
│ Client  │ ──▶ │   API   │ ──▶ │   DB    │
└─────────┘     └─────────┘     └─────────┘
\`\`\`

## Entry Points

| Entry Point | Purpose | Location |
|-------------|---------|----------|
| `main()` | CLI entry | `src/cli.py:15` |
| `app` | Web server | `src/app.py:8` |

## Key Files

### `src/core/engine.py`

**Purpose:** Core processing logic

**Key functions:**
- `process()` - Main processing entry (line 45)
- `validate()` - Input validation (line 89)
- `transform()` - Data transformation (line 123)

**Code sample:**
\`\`\`python
# Lines 45-55 (via: sed -n '45,55p' src/core/engine.py)
def process(data: dict) -> Result:
    validated = self.validate(data)
    transformed = self.transform(validated)
    return self.store(transformed)
\`\`\`

### `src/api/routes.py`

**Purpose:** HTTP route handlers

[Continue for each key file...]

## Data Flow

1. Request arrives at `/api/process`
2. `routes.py:handle_process()` validates auth
3. `engine.py:process()` orchestrates the work
4. Results stored via `db.py:save()`
5. Response returned to client

## Key Patterns

- [pattern] Factory pattern for client creation
- [pattern] Repository pattern for data access
- [pattern] Middleware chain for auth

## Gotchas

- Config loaded from env vars, not file
- Rate limiting happens in nginx, not app
- Async handlers but sync database calls

## Observations

- [architecture] Clean separation of routes/logic/data
- [understanding] Core logic in engine.py, everything else is glue
```

## Triggering a Walkthrough

### Full Project

```text
Read the source and create a linear walkthrough explaining how
this project works. Use grep/sed to include actual code snippets.
Save the walkthrough to Basic Memory.
```

### With Showboat (Captures Evidence)

```text
Fetch the README and source files, then use showboat to create
walkthrough.md - use `showboat exec` with grep/sed to include
code snippets so they're verified against the actual source.
```

## Tips

1. **Start with tests** - Tests often reveal intended usage
2. **Find the happy path first** - Understand normal flow before edge cases
3. **Follow imports** - See what each file depends on
4. **Check config** - Configuration reveals runtime behavior
5. **Read error handling** - Shows what can go wrong

## Related Skills

- `deep-dive` - More thorough investigation with questioning
- `code-recipes` - Extract reusable patterns discovered
- `knowledge-capture` - Save insights as discrete notes
