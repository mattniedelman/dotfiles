# Knowledge Organize - API Reference

Practical Basic Memory MCP query patterns for each organization capability.

## Find Orphan Notes

Notes with no incoming or outgoing relations.

```python
# List all notes, then check for those with no relations
list_directory(directory="", recursive=True)  # Basic Memory MCP
# Then for each note:
read_note(identifier="note-permalink")  # Check for Relations section
```

```python
# Search for notes explicitly flagged as isolated
search_notes(query="orphan unlinked isolated", page_size=20)  # Basic Memory MCP
```

Strategy:
Read notes that appear in no other note's Relations section.
Cross-reference by building context from hub notes and seeing what falls
outside.

## Suggest Relations

Find notes that should be connected but aren't.

```python
# Get all content in a topic area
build_context(
    url="memory://topic-area/*",
    depth=2,
)  # Basic Memory MCP

# Search for notes by keyword to find potential connections
search_notes(query="keyword from note A", page_size=10)  # Basic Memory MCP
```

Pattern:
Read two notes, compare their content, suggest relation types:
- `relates_to` - shares a topic
- `implements` - one instantiates the other
- `supersedes` - newer version
- `extends` - builds on
- `informs` - provides context for

## Identify Duplicates

Notes covering the same ground.

```python
# Find notes with similar titles
search_notes(query="title keywords", page_size=20)  # Basic Memory MCP

# Find notes with same tags
search_by_metadata(
    metadata_field="tags",
    metadata_value="debugging",
)  # Basic Memory MCP
```

When two notes overlap significantly:
1. Read both in full
2. Identify which is more complete
3. Propose:
   merge into one, or add `supersedes` relation

## Suggest Tags

Recommend tags based on existing vocabulary.

```python
# Find commonly used tags
recent_activity(timeframe="1 month")  # Basic Memory MCP - reveals tag patterns
search_notes(query="tags: debugging")  # Basic Memory MCP
```

Build a vocabulary from existing tags, then compare note content against it.
Suggest the 2-5 most relevant existing tags for each untagged note.

## Create Hub Notes

Index notes that connect related content.

```python
# Find notes in a topic area
search_notes(
    query="topic keyword",
    page_size=30,
)  # Basic Memory MCP

# Build full context map
build_context(
    url="memory://folder/*",
    depth=1,
)  # Basic Memory MCP
```

Hub note structure:

```markdown
# [Topic] Index

Overview of [topic] knowledge.

## Notes

- [[permalink/to/note-a|Note A Title]]: Brief description
- [[permalink/to/note-b|Note B Title]]: Brief description

## Relations

- organizes [[Note A]]
- organizes [[Note B]]
```

## Analyze Structure

Check that notes follow standard templates.

Standard note structure:

```markdown
---
title: "Title"
tags: [tag1, tag2]
---

# Title

[Content]

## Observations
- [type] key insight

## Relations
- relates_to [[Other Note]]
```

Structural checks:
- Has frontmatter with `title` and `tags`
- Has at least one heading
- Has an Observations section (for research notes)
- Has a Relations section (for connected notes)
- Uses `[[permalink|Title]]` format for body links

## Knowledge Graph Audit

Comprehensive review of a person, project, or repo.

```python
# Find all notes related to a subject
build_context(
    url="memory://subject-name",
    depth=3,
)  # Basic Memory MCP

# Check recent activity
recent_activity(
    timeframe="1 month",
    project="main",
)  # Basic Memory MCP
```

Audit output format:

```markdown
## Audit: [Subject]

**Total notes:** N
**Orphan notes:** N
**Missing relations:** N
**Tag inconsistencies:** N

### Orphans
- [Note title] - no incoming or outgoing relations

### Suggested Relations
- [[A]] -> relates_to -> [[B]] (both discuss X)

### Duplicate Candidates
- [[A]] and [[B]] both cover [topic]
```

## Fix Wiki Links

Correct broken or Obsidian-incompatible links.

**Problem:** `[[Creating an ADR]]` fails in Obsidian (files are slugified).

**Fix:** Use `[[permalink|Display Title]]` format.

```python
# Find notes with potentially broken links
search_notes(query="[[")  # Basic Memory MCP - finds notes with wiki links
```

Correction pattern:
- `[[Note Title]]` -> `[[folder/note-title|Note Title]]`
- `[[note-slug]]` -> `[[folder/note-slug|Human Title]]`

Use the note's permalink (path without `.md`) as the link target.

## Convert Session References

Transform session IDs to wiki links in arc summaries.

Pattern:
arc notes often reference sessions by ID (e.g., `abc12345`).
Convert to proper links once session notes exist.

```python
# Find the session note
search_notes(
    query="abc12345",
    tags=["case-study"],
)  # Basic Memory MCP
```

Before:
`Session abc12345` After:
`[[journal/sessions/2025/11/note-title|Session:
What I Was Doing]]`
