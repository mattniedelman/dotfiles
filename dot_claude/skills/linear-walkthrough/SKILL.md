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

```python
# Find main entry points (Serena MCP)
find_symbol(name_path_pattern="main", include_info=True)
find_symbol(name_path_pattern="app", include_info=True)

# For web apps (Serena MCP)
get_symbols_overview(relative_path="src/routes", depth=1)
get_symbols_overview(relative_path="src/api", depth=1)
```

### 3. Trace Key Flows

Follow the critical paths:

```text
Request -> Router -> Handler -> Service -> Database -> Response
```

### 4. Document with Real Code

**CRITICAL:** Include actual code snippets by reading source files directly.
Never copy-paste from memory.
This ensures accuracy and prevents hallucination.

```python
# Read specific lines from a file
Read(file_path="src/auth/login.py", offset=45, limit=16)

# Find all occurrences of a function/pattern
Grep(pattern="def authenticate", path="src/auth/service.py", output_mode="content", -A=5)

# Find all route handlers
Grep(pattern="@app.route", path="src/routes", type="py", output_mode="content")
```

### 5. Save to Basic Memory

```python
write_note(
    title="Walkthrough: {Project Name}",
    content="[walkthrough content]",
    directory="knowledge/walkthroughs",
    tags=["walkthrough", "understanding", "{project}"],
)  # Basic Memory MCP
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
```python
# Lines 45-55 (Read offset=45 limit=11)
def process(data: dict) -> Result:
    validated = self.validate(data)
    transformed = self.transform(validated)
    return self.store(transformed)
```

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
Read the source files and create a linear walkthrough explaining how
this project works. Include actual code snippets by reading files with
the Read tool. Save the walkthrough to Basic Memory.
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
