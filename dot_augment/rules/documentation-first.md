---
type: always_apply
priority: CRITICAL
description: MANDATORY documentation lookup before ANY work involving libraries, tools, frameworks, or APIs - never guess syntax or functionality
---

# Documentation-First Rule

## ⚠️ CRITICAL: NEVER GUESS SYNTAX OR FUNCTIONALITY ⚠️

**You are heavily penalized for guessing at syntax, API behavior, or library
functionality without first consulting documentation.**

Violations of this rule are treated with the same severity as:

- Creating unsolicited files
- Violating scope boundaries
- Missing downstream changes

## Mandatory Documentation Lookup

**Before writing ANY code** that uses external libraries, frameworks, tools,
APIs, or services:

1. **STOP** - Do not write code based on memory or assumptions
2. **LOOK UP** - Fetch authoritative documentation first
3. **VERIFY** - Confirm syntax, parameters, return types, and behavior
4. **THEN CODE** - Only write code after documentation confirms correctness

## Documentation Discovery Workflow

### Step 1: Try llms.txt First (Preferred)

Always check for an llms.txt file at the documentation root:

```text
https://docs.example.com/llms.txt
https://example.com/llms.txt
```

Use `web-fetch` to retrieve it.
This file provides a structured index optimized for AI consumption.

### Step 2: Fetch Relevant Pages

From llms.txt, identify and fetch the specific documentation pages needed for
the current task.

### Step 3: Fallback to crwl

If `web-fetch` fails (403, rate-limited, bot-blocked), use the `crwl` tool:

```bash
crwl <url>
```

### Step 4: Check Crawled Docs

If documentation was previously crawled, search Basic Memory:

```python
mcp__docs - crawler__check_docs(source_name="library-name")
mcp__basic - memory__search_notes(query="topic", tags=["docs"])
```

### Step 5: Web Search as Last Resort

Only if all above fail, use `web-search` to find documentation.

## What Requires Documentation Lookup

| Category | Examples |
|----------|----------|
| **Library APIs** | Function signatures, class methods, parameters |
| **Framework patterns** | Routing, middleware, dependency injection |
| **Tool usage** | CLI flags, configuration options |
| **Service APIs** | REST endpoints, GraphQL schemas, request/response formats |
| **Language features** | New syntax, standard library functions |
| **Configuration** | File formats, valid options, defaults |

## Prohibited Behaviors

### NEVER Do These

- ❌ Write code using library APIs from memory
- ❌ Assume function signatures or parameter names
- ❌ Guess at configuration options or defaults
- ❌ Infer behavior from similar libraries
- ❌ Use outdated knowledge about rapidly-changing tools
- ❌ Assume version-specific features without checking version

### Example Violations

| Violation | Correct Approach |
|-----------|------------------|
| "I'll use `requests.get()` with `timeout` param" | Fetch requests docs, verify `timeout` parameter exists and its type |
| "FastAPI uses `@app.get()` decorator" | Fetch FastAPI docs, confirm decorator syntax |
| "Pydantic v2 uses `model_validator`" | Fetch Pydantic v2 docs, verify validator API |

## Acceptable Exceptions

Documentation lookup is NOT required for:

- Standard library functions you're using inline (print, len, etc.)
- Code patterns already visible in the current codebase
- Syntax already shown in files you've read in this session
- User has provided the exact code/syntax to use

## Self-Check Before Coding

Before writing any code involving external dependencies, ask yourself:

1. Have I fetched documentation for this library/tool/API?
2. Have I verified the exact function signatures I'm using?
3. Have I confirmed the parameter names and types?
4. Have I checked for version-specific behavior?

If ANY answer is "no" - STOP and fetch documentation first.

## Enforcement

When you use a library, framework, or tool without documenting your source:

- You MUST cite where you verified the syntax
- You MUST show evidence of documentation lookup
- Responses without evidence are considered violations

## Cross-Reference

Related skill:
`using-documentation` - Detailed workflow for documentation access
