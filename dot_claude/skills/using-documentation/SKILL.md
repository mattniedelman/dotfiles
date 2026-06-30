---
name: using-documentation
description: Use when accessing library documentation, asking about software capabilities, or checking what a tool can do - starts with llms.txt, falls back to WebFetch then WebSearch
---

# Using Documentation

This skill helps access library/framework documentation effectively using
WebFetch, the crwl CLI (if available), and Basic Memory integration.

## When to Use

Use this skill when:

- Working with a new library or framework
- Need API reference or examples for a library
- User asks "how do I use X?", "what's the API for Y?"
- **User asks about the capabilities of software** ("can X do Y?", "does X
  support Y?", "what can X do?")
- Designing a feature using external libraries
- Implementing code that depends on library behavior
- User mentions a library/framework and needs guidance
- **Before starting work** on any task involving libraries or frameworks

## Pre-Work Documentation Check (CRITICAL)

**Before starting work** on any task involving a library, framework, tool, or
service, check if documentation has already been crawled or is available.

## Workflow

This is the single canonical workflow for accessing documentation, answering
capability questions ("can X do Y?", "does X support Y?"), and reviewing a
tool's docs. The fetch ladder is the same in every case:
llms.txt -> WebFetch -> crwl -> WebSearch.

### 1. Check If Documentation Exists

First, check whether we already have the docs in Basic Memory:

```python
search_notes(query="library-name", tags=["docs"])  # Basic Memory MCP
```

- **Exists and fresh:** proceed to step 4 (search/retrieve).
- **Exists but stale (>30 days):** suggest a refresh if the library has likely
  been updated; use existing if the user needs info quickly.
- **Does not exist:** fetch it (step 2).

### 2. Fetch via the Ladder

Try each step in order; advance only when the current step fails or is
unavailable.

1. **llms.txt first** -- fetch `https://docs.example.com/llms.txt` or
   `https://example.com/llms.txt`. This file is a structured index optimized
   for AI consumption: use it to see the full scope of available docs, identify
   the most relevant pages, and navigate directly to authoritative sources.
2. **WebFetch** -- fetch the specific pages (listed in llms.txt, or the known
   URL):
   ```python
   WebFetch(url="https://docs.library.com/api/reference")
   ```
3. **crwl** (optional CLI) -- fall back here if WebFetch fails (403,
   rate-limited, bot-blocked) and crwl is installed:
   ```bash
   crwl --version            # confirm it is available first
   crwl https://docs.library.com/api/reference
   ```
4. **WebSearch** -- fall back here if no llms.txt exists, crwl is unavailable,
   and direct fetching fails. Also use to supplement for very recent changes.

### 3. Store (Optional)

When the docs are worth keeping, save them to Basic Memory so future lookups
hit step 1 instead of re-fetching.

### 4. Search for Information

Once docs are stored, use Basic Memory to find specific info:

```python
# Search for specific topic
search_notes(
    query="pydantic field validation",
    tags=["docs", "pydantic"],
)  # Basic Memory MCP

# Build context around a concept
build_context(
    url="memory://docs/pydantic/*",
    depth=2,
)  # Basic Memory MCP
```

## Available Tools

| Tool          | Purpose                                              |
| ------------- | ---------------------------------------------------- |
| `WebFetch`    | Fetch a single documentation page                    |
| `WebSearch`   | Find documentation URLs when unknown                 |
| `crwl`        | Crawl documentation when WebFetch is blocked (CLI)   |
| `search_notes`| Search previously stored docs in Basic Memory        |
| `build_context`| Navigate related documentation in Basic Memory      |

**Note:** `crwl` is an optional external CLI tool.
Use `WebFetch` and `WebSearch` as the primary fallback when crwl is unavailable.

## Example Conversations

**User:** "I need to use Pydantic for validation"

1. Check if Pydantic docs exist in Basic Memory
2. If not:
   Try llms.txt at `https://docs.pydantic.dev/llms.txt`
3. Fetch relevant pages from llms.txt index
4. Present relevant information organized by use case

**User:** "How does FastAPI handle dependency injection?"

1. Check for FastAPI docs in Basic Memory
2. Search for "dependency injection" in stored docs
3. If not found, fetch from FastAPI documentation
4. Synthesize into clear explanation with examples

**User:** "What's the signature for httpx.AsyncClient.get?"

1. Check for httpx docs in Basic Memory
2. Search for "AsyncClient.get"
3. If not found, fetch httpx API reference
4. Return exact signature and parameters

## Known llms.txt URLs

Skip the discovery step for these libraries -- fetch the index directly:

| Library | llms.txt URL |
| ------- | ------------ |
| Pydantic | `https://docs.pydantic.dev/latest/llms.txt` (301-redirects to `https://pydantic.dev/docs/validation/latest/llms.txt`) |

For any other library, derive the candidate URL from its docs root
(`<docs-root>/llms.txt`) per step 2 of the Workflow.

## Best Practices

1. **Check before fetching** - Don't re-fetch unnecessarily
2. **Match depth to need** - Quick fetch for lookups, full crawl for learning
3. **Combine with WebSearch** - For very recent changes, supplement with search
4. **Update stale docs** - Suggest refresh for docs older than 30 days
5. **Search for llms.txt** - When reviewing external documentation
