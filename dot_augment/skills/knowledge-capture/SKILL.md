---
name: knowledge-capture
description: Capture insights, decisions, and learnings from conversations into structured Basic Memory notes with observations and relations
---

# Knowledge Capture

This skill helps you capture valuable information from conversations into Basic
Memory's knowledge graph using structured notes with observations and relations.

## CRITICAL: Mandatory Triggers

### Session Start (MUST check basic-memory)

When the user's first message involves ANY of these, IMMEDIATELY call
`recent_activity` and/or `search_notes`:

- A named project, repository, or codebase
- A topic previously discussed (architecture, patterns, decisions)
- References to "we did", "last time", "before", or similar prior work
- Technical decisions or design questions

### Task Completion (MUST consider notes update)

After completing ANY of these, explicitly evaluate whether notes need updating:

- Implementing a feature or fixing a non-trivial bug
- Making an architectural or design decision
- Discovering how something works (debugging, investigation)
- Setting up infrastructure, environments, or tooling
- Resolving a problem that took significant effort

**Required**:
Either update relevant notes OR state "No notes update needed because [reason]."

### End of Session Checklist

Before ending a substantive work session, review:

1. **New knowledge**:
   Did we learn anything worth preserving?
2. **Changed decisions**:
   Did any documented decisions change?
3. **Stale notes**:
   Did we encounter outdated information?
4. **Patterns discovered**:
   Did we establish patterns worth documenting?

If any answer is "yes", update notes before concluding.

## When to Use

Use this skill when:

- Important decisions are made during a conversation
- Technical insights or patterns are discovered
- Problems are solved and the solution should be preserved
- Design trade-offs are discussed
- Architecture or implementation approaches are chosen
- Learnings from debugging or investigation emerge
- Discovering where functionality is implemented in a codebase
- Mapping out system architecture or component relationships

## Capture Process

### 1. Identify Valuable Information

Look for:

- **Decisions**:
  Choices made and their rationale
- **Insights**:
  New understanding or "aha" moments
- **Patterns**:
  Reusable approaches or solutions
- **Trade-offs**:
  Options considered and why one was chosen
- **Learnings**:
  What worked, what didn't, and why
- **Context**:
  Background that would help future understanding

### 2. Structure the Note

Use Basic Memory's knowledge format:

```markdown
---
title: Descriptive Title
type: note
tags:
- relevant
- tags
---

# Title

## Context
Brief background explaining the situation.

## Content
Main content organized logically.

## Observations

- [decision] What was decided and why #tag
- [insight] Key understanding gained #tag
- [pattern] Reusable approach identified #tag
- [learning] What we learned from this #tag
- [tradeoff] Option A chosen over B because... #tag

## Relations

- relates-to \[[Related Concept]\]
- implements \[[Parent Spec or Design]\]
- learned-from \[[Source of Learning]\]
```

### 3. Choose Appropriate Categories

Common observation categories:

- `[decision]` - Choices made
- `[insight]` - Understanding gained
- `[pattern]` - Reusable approaches
- `[learning]` - Lessons learned
- `[tradeoff]` - Options weighed
- `[problem]` - Issues identified
- `[solution]` - Fixes applied
- `[architecture]` - Structural decisions
- `[implementation]` - Code-level choices
- `[constraint]` - Limitations discovered
- `[requirement]` - Needs identified

### 4. Create Meaningful Relations

Link to related knowledge:

- `relates-to` - General association
- `implements` - Realizes a spec or design
- `extends` - Builds upon existing concept
- `learned-from` - Source of insight
- `enables` - Makes something possible
- `depends-on` - Requires another concept
- `solves` - Addresses a problem

### 5. Use Correct Link Formats

**Body/navigation links** (clickable in Obsidian):

```markdown
See [[specs/my-spec-name|My Spec Name]] for details.
```

- Use `[[permalink|Display Title]]` format
- `permalink` is the note path without `.md`
- Required because filenames are slugified (title-only links won't resolve)

**Relations section** (for Basic Memory knowledge graph):

```markdown
## Relations

- implements \[[Parent Spec]\]
- relates-to \[[Related Topic]\]
```

- Use escaped brackets `\[[...]]\]` for semantic relations
- These don't need to be clickable - they're for the knowledge graph

### 6. Use Inline Hashtags for Attributes

For skills, strengths, and categorical attributes (especially in person notes),
use **inline hashtags**:

```markdown
## Technical Strengths

#architecture-design #api-development #aws-integration #documentation
```

**Why inline hashtags:**

- More compact and scannable than bullet lists
- Automatically linked by Obsidian for navigation
- No duplication between frontmatter tags and body content
- Works well for both discovery and search

**When NOT to use hashtags:**

- For relationships to other notes (use wiki links)
- For observations in the Relations section (use relation types)
- For structural metadata (use frontmatter)

### 7. File Naming for Obsidian Compatibility

For notes that will be frequently wiki-linked (teams, indexes, key concepts),
**use the exact title with spaces as the filename**:

- ✅ `AI Engineering Team.md` - resolves `[[AI Engineering Team]]`
- ❌ `ai-engineering-team.md` - may NOT resolve even with aliases

Obsidian's alias resolution can be unreliable.
Direct filename matching is most reliable for wiki-link resolution.

## MCP Tools to Use

```python
# Write a new note
mcp__basic-memory__write_note(
    title="Your Note Title",
    content="Full markdown content...",
    folder="appropriate/folder",
    tags=["tag1", "tag2"],
    project="main"  # or appropriate project
)

# Search for related notes to link
mcp__basic-memory__search_notes(
    query="relevant terms",
    project="main"
)

# Read existing notes for context
mcp__basic-memory__read_note(
    identifier="note-title-or-permalink",
    project="main"
)
```

## Folder Organization

Choose appropriate folders:

- `artifacts/architecture/` - Architecture decisions and system designs
- `artifacts/specs/` - Design specs and requirements
- `artifacts/research/` - Research reports and findings
- `artifacts/patterns/` - Reusable approaches and patterns
- `knowledge/concepts/` - Technical concepts and learnings
- `knowledge/technologies/` - Technology notes
- `_meta/working/` - Work-in-progress notes
- `journal/sessions/YYYY/MM/` - Session case studies (by date)

## Examples

### Capturing a Technical Decision

```markdown
---
title: FastAPI Async Client Pattern
type: note
tags:
- architecture
- fastapi
- async
---

# FastAPI Async Client Pattern

## Context
During implementation of MCP tools, we needed to decide how to handle HTTP client lifecycle.

## Decision
Use context manager pattern for HTTP clients instead of module-level singletons.

## Rationale
- Proper resource management
- Supports three deployment modes (local ASGI, CLI cloud, cloud app)
- Auth happens at client creation, not per-request
- Enables dependency injection for testing

## Observations

- [decision] Context manager pattern for HTTP clients enables proper resource cleanup #architecture
- [pattern] Factory pattern allows different client configurations per deployment mode #flexibility
- [tradeoff] Slightly more verbose than singleton but much more flexible #engineering

## Relations

- implements \[[SPEC-16 MCP Cloud Service Consolidation]\]
- enables \[[Cloud App Integration]\]
```

### Capturing a Debugging Insight

```markdown
---
title: SQLite WAL Mode Performance Fix
type: note
tags:
- debugging
- sqlite
- performance
---

# SQLite WAL Mode Performance Fix

## Problem
Sync operations were slow with multiple concurrent writes.

## Investigation
Found that default SQLite journaling was causing lock contention.

## Solution
Enabled WAL (Write-Ahead Logging) mode for the database connection.

## Observations

- [problem] Default SQLite journaling causes lock contention under concurrent writes #performance
- [solution] WAL mode significantly improves concurrent write performance #sqlite
- [learning] Always consider WAL mode for SQLite in applications with concurrent access #database

## Relations

- solves \[[Sync Performance Issues]\]
- relates-to \[[SPEC-19 Sync Performance]\]
```

## What NOT to Store

Avoid storing information that:

- Is trivial or easily re-discoverable
- Contains sensitive credentials or secrets
- Is highly volatile and likely to become stale quickly
- Duplicates information already well-documented elsewhere
- Is specific to a single, one-off task with no future relevance

## Best Practices

1. **Capture immediately** - Write notes while context is fresh
2. **Be specific** - Include concrete details, not vague summaries
3. **Link liberally** - More relations = better knowledge graph
4. **Use tags** - Enable discovery via search
5. **Include context** - Future you won't remember the situation
6. **Prefer facts over opinions** - Observations should be verifiable
7. **Keep notes atomic** - One concept per note when possible
8. **Keep notes current** - Update when decisions change or info becomes stale
