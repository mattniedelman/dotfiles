---
type: always_apply
priority: HIGH
description: Guidelines for reviewing documentation, including llms.txt discovery
last_updated: 2025-02-11
---

# Documentation Review Guidelines

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
   specific documentation pages listed in llms.txt

## Documentation Fetching Workflow

| Step | Action |
|------|--------|
| 1 | Identify the documentation source (official docs URL) |
| 2 | Attempt to fetch `llms.txt` from the docs root |
| 3 | If found, parse the index and identify relevant sections |
| 4 | Fetch specific pages needed for the task |
| 5 | If no llms.txt exists, fall back to web search or direct URL fetching |

## Examples

**Reviewing Augment CLI documentation:**

```text
1. Fetch https://docs.augmentcode.com/llms.txt
2. Parse available pages
3. Fetch specific pages relevant to the user's question
```

**Reviewing a library's API:**

```text
1. Fetch https://library-docs.io/llms.txt
2. If not found, try https://library-docs.io/api/llms.txt
3. Fall back to web search if unavailable
```

## Integration with Existing Rules

This rule complements the Augment workspace rule in
`.augment/rules/augment-workspace.md` which specifies fetching `llms.txt` for
Augment CLI documentation specifically.
This rule generalizes that pattern to all documentation review tasks.
