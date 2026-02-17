---
name: using-documentation
description: Access and use library documentation intelligently - check existing crawled docs, trigger crawls when needed, and search for specific information
---

# Using Documentation

This skill helps access library/framework documentation effectively using the
docs-crawler MCP server and Basic Memory integration.

## When to Use

Use this skill when:

- Working with a new library or framework
- Need API reference or examples for a library
- User asks "how do I use X?", "what's the API for Y?"
- Designing a feature using external libraries
- Implementing code that depends on library behavior
- User mentions a library/framework and needs guidance

## Prerequisites

The `docs-crawler` MCP server must be configured in Augment settings.

## Workflow

### 1. Check If Documentation Exists

First, check if we already have crawled documentation:

```python
# By URL
mcp__docs-crawler__check_docs(source_url="https://docs.pydantic.dev/")

# By name
mcp__docs-crawler__check_docs(source_name="pydantic")
```

### 2. Decision: Crawl or Use Existing

**If docs don't exist:**

- Ask user if they want to crawl the documentation
- Determine appropriate depth ("quick" for basics, "deep" for comprehensive)

**If docs exist but are stale (>30 days):**

- Suggest refresh if the library has likely been updated
- Use existing if user needs info quickly

**If docs exist and fresh:**

- Proceed to search/retrieve

### 3. Crawl Documentation (When Needed)

```python
# Quick crawl - gets overview, main concepts, key APIs
mcp__docs-crawler__crawl_docs(
    url="https://docs.library.com/",
    depth="quick",
    wait=True  # or False for background
)

# Deep crawl - comprehensive documentation
mcp__docs-crawler__crawl_docs(
    url="https://docs.library.com/",
    depth="deep",
    wait=True
)
```

### 4. Search for Information

After docs are stored, use Basic Memory to find specific info:

```python
# Search for specific topic
mcp__basic-memory__search_notes(
    query="pydantic field validation",
    tags=["docs", "pydantic"]
)

# Build context around a concept
mcp__basic-memory__build_context(
    url="memory://docs/pydantic/examples",
    depth=2
)
```

### 5. Use the Three Pillars

Documentation is organized into three types:

**Memory** (`docs/{source}/memory/`):

- API reference, function signatures
- Parameter types and return values
- Use for:
  "What parameters does X accept?"

**Reasoning** (`docs/{source}/reasoning/`):

- Design philosophy, best practices
- When and why to use certain features
- Use for:
  "When should I use X vs Y?"

**Examples** (`docs/{source}/examples/`):

- Code samples, tutorials
- Usage patterns
- Use for:
  "Show me how to use X"

## Depth Strategy Guide

| Scenario | Recommended Depth |
| -------- | ----------------- |
| Quick API lookup | quick |
| Learning new library | deep |
| Troubleshooting specific issue | quick |
| Comprehensive design work | deep |
| Time-sensitive task | quick |
| New team member onboarding | deep |

## Available Tools

| Tool | Purpose |
| ---- | ------- |
| `check_docs` | Check if docs exist for a source |
| `crawl_docs` | Crawl and store documentation |
| `crawl_status` | Check status of async crawl |
| `list_sources` | List all crawled doc sources |
| `refresh_docs` | Re-crawl an existing source |

## Example Conversations

**User:** "I need to use Pydantic for validation"

1. Check if Pydantic docs exist
2. If not:
   "I can crawl the Pydantic docs.
   Quick overview or deep dive?"
3. If yes:
   Search for validation-related content
4. Present relevant information organized by use case

**User:** "How does FastAPI handle dependency injection?"

1. Check for FastAPI docs
2. Search reasoning pillar for "dependency injection"
3. Search examples pillar for DI patterns
4. Synthesize into clear explanation with examples

**User:** "What's the signature for httpx.AsyncClient.get?"

1. Check for httpx docs
2. Search memory pillar for "AsyncClient.get"
3. Return exact signature and parameters

## Best Practices

1. **Check before crawling** - Don't re-crawl unnecessarily
2. **Match depth to need** - Quick for lookups, deep for learning
3. **Use pillars intentionally** - Memory for facts, reasoning for why, examples
   for how
4. **Combine with web search** - For very recent changes, supplement with
   web-fetch
5. **Update stale docs** - Suggest refresh for docs older than 30 days
