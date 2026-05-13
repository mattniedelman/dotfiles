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

### 1. Check If Documentation Exists

First, check if we already have documentation in Basic Memory:

```python
search_notes(query="library-name", tags=["docs"])  # Basic Memory MCP
```

### 2. Decision: Fetch or Use Existing

**If docs don't exist:**

- Try llms.txt first (see below)
- Use `WebFetch` for specific documentation pages
- Fall back to `crwl` if `WebFetch` fails (403, rate-limited, bot-blocked)
- Fall back to `WebSearch` if crwl is unavailable

**If docs exist but are stale (>30 days):**

- Suggest refresh if the library has likely been updated
- Use existing if user needs info quickly

**If docs exist and fresh:**

- Proceed to search/retrieve

### 3. Fetch Documentation (When Needed)

**Option A:
WebFetch (always available)**

```python
WebFetch(url="https://docs.library.com/api/reference")
```

**Option B:
crwl CLI (if installed)**

```bash
# Check if crwl is available first
crwl --version

# Crawl documentation pages
crwl https://docs.library.com/
crwl https://docs.library.com/api/reference
```

If crwl is not installed, fall back to `WebFetch` or `WebSearch`.

### 4. Search for Information

After docs are stored, use Basic Memory to find specific info:

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

## Capability Questions Workflow

When asked about software capabilities ("can X do Y?", "does X support Y?",
"what features does X have?"):

1. **Try llms.txt first** - Fetch `https://docs.example.com/llms.txt` or
   `https://example.com/llms.txt`
2. **Use WebFetch for specific pages** - If llms.txt lists relevant pages
3. **Fall back to crwl** - If WebFetch fails (403, rate-limited, bot-blocked)
   and crwl is installed:
   ```bash
   crwl <url>
   ```
4. **Fall back to WebSearch** - If crwl unavailable or also blocked
5. **Search stored docs** - If docs are already stored in Basic Memory

## llms.txt Discovery

When asked to review documentation for any tool, library, framework, or service:

1. **Search for llms.txt first** - Look for an `llms.txt` file at the
   documentation root
   - Common locations:
     `https://docs.example.com/llms.txt`, `https://example.com/llms.txt`
   - This file provides a structured index optimized for AI consumption

2. **Use llms.txt as the primary index** - When found, use it to:
   - Understand the full scope of available documentation
   - Identify the most relevant pages for the current task
   - Navigate directly to authoritative sources

3. **Fetch relevant pages from the index** - Based on the user's request, fetch
   specific documentation pages listed in llms.txt using `WebFetch`

4. **Fall back to crwl if WebFetch fails** - Some sites block automated
   fetching.
   Use `crwl` as an alternative if installed:
   ```bash
   crwl <url>
   ```

5. **Fall back to WebSearch** - If no llms.txt exists, crwl unavailable, and
   direct fetching fails

## Best Practices

1. **Check before fetching** - Don't re-fetch unnecessarily
2. **Match depth to need** - Quick fetch for lookups, full crawl for learning
3. **Combine with WebSearch** - For very recent changes, supplement with search
4. **Update stale docs** - Suggest refresh for docs older than 30 days
5. **Search for llms.txt** - When reviewing external documentation
