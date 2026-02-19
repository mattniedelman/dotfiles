---
name: knowledge-organize
description: Help organize, link, and maintain the Basic Memory knowledge graph - find orphan notes, suggest relations, identify duplicates, and improve overall knowledge structure
---

# Knowledge Organize

This skill helps users maintain a healthy, well-connected knowledge graph.
As notes accumulate, it becomes valuable to periodically organize, link, and
curate the knowledge base.

## When to Use

Use this skill when:

- User asks to organize their notes
- User wants to find connections between notes
- User mentions orphan or unlinked notes
- User wants to clean up or improve their knowledge base
- User asks about duplicate or similar notes
- User wants help with folder organization
- User asks to review or audit their notes
- Phrases like "help me organize", "find related notes", "what's not linked",
  "clean up my notes"

## Organization Capabilities

### 1. Find Orphan Notes

Identify notes that have no relations to other notes - they're isolated in the
knowledge graph.

```python
# Get all notes
mcp__basic-memory__search_notes(
    query="*",
    page_size=50,
    project="main"
)

# For each note, check if it has relations
# Orphans have empty Relations sections
```

**What to do with orphans:**

- Suggest potential relations based on content similarity
- Ask if they should be linked to existing topics
- Propose creating hub notes to connect related orphans

### 2. Suggest Relations

Analyze note content and suggest meaningful connections.

```python
# Read a note
mcp__basic-memory__read_note(
    identifier="note-to-analyze",
    project="main"
)

# Search for potentially related notes
mcp__basic-memory__search_notes(
    query="key terms from the note",
    project="main"
)

# Suggest relations based on:
# - Shared topics or concepts
# - Complementary content (problem/solution, question/answer)
# - Sequential relationship (part 1, part 2)
# - Hierarchical (parent concept, child detail)
```

**Relation types to suggest:**

- `relates-to` - General topical connection
- `extends` - Builds upon or expands
- `implements` - Realizes a concept
- `depends-on` - Requires understanding of
- `contradicts` - Presents alternative view
- `learned-from` - Source of insight
- `enables` - Makes something possible

### 3. Identify Similar/Duplicate Notes

Find notes that may cover the same topic.

```python
# Search for notes with similar titles or content
mcp__basic-memory__search_notes(
    query="topic keywords",
    project="main"
)

# Compare results for overlap
# Look for:
# - Similar titles
# - Overlapping observations
# - Same tags
# - Related timestamps (created around same time)
```

**Actions for duplicates:**

- Merge into a single comprehensive note
- Link them with `supersedes` or `updates` relations
- Differentiate by adding context about their distinct focus

### 4. Folder Organization Review

Analyze folder structure and suggest improvements.

```python
# List directory structure
mcp__basic-memory__list_directory(
    dir_name="/",
    depth=3,
    project="main"
)

# Identify:
# - Overcrowded folders
# - Single-note folders
# - Inconsistent naming
# - Notes that might belong elsewhere
```

**Organization suggestions:**

- Group related notes into topic folders
- Create subfolders for large categories
- Suggest consistent naming conventions
- Move misplaced notes

### 5. Tag Consistency

Review and normalize tags across notes.

```python
# Search notes to analyze tag patterns
mcp__basic-memory__search_notes(
    query="*",
    page_size=100,
    project="main"
)

# Look for:
# - Similar tags (architecture vs arch)
# - Unused tags
# - Over-used generic tags
# - Missing tags on relevant notes
```

**Tag improvements:**

- Suggest tag standardization (pick one variant)
- Propose new tags for common themes
- Identify notes missing obvious tags

### 6. Create Index/Hub Notes

Generate notes that serve as navigation hubs for related topics.

```python
# After identifying a cluster of related notes
mcp__basic-memory__write_note(
    title="Architecture Decisions Index",
    content="""---
title: Architecture Decisions Index
type: index
tags:
- architecture
- index
---

# Architecture Decisions Index

A hub linking all architecture-related decisions and patterns.

## Decisions

- [[decisions/database-selection-decision|Database Selection Decision]]
- [[decisions/api-design-patterns|API Design Patterns]]
- [[decisions/authentication-architecture|Authentication Architecture]]

## Patterns

- [[patterns/repository-pattern|Repository Pattern]]
- [[patterns/async-client-pattern|Async Client Pattern]]

## Observations

- [index] Central hub for architecture knowledge #navigation

## Relations

- indexes [[Architecture]]
""",
    folder="indexes",
    project="main"
)
```

### 7. Enrich Sparse Notes

Find notes lacking observations or structure and suggest improvements.

```python
# Read a sparse note
mcp__basic-memory__read_note(
    identifier="sparse-note",
    project="main"
)

# If missing:
# - Observations section -> suggest categories
# - Relations section -> suggest links
# - Tags -> suggest relevant tags
# - Context -> suggest adding background
```

## Organization Workflows

### Quick Health Check

A fast overview of knowledge base status:

1. Count total notes
2. Identify orphan count
3. List recently modified
4. Check for obvious duplicates
5. Report folder distribution

### Deep Organization Session

Thorough review and improvement:

1. **Audit phase** - Catalog all notes, identify issues
2. **Orphan phase** - Address unlinked notes
3. **Relation phase** - Suggest new connections
4. **Duplicate phase** - Merge or differentiate similar notes
5. **Structure phase** - Reorganize folders if needed
6. **Index phase** - Create hub notes for major topics

### Comprehensive Knowledge Graph Audit

A periodic, thorough audit of the entire knowledge graph:

#### Person Notes Audit

1. Query GitHub for each person's recent commit activity (last 30-60 days)
2. Update "Total Commits" count if changed
3. Verify "Primary Repositories" list based on current activity
4. Ensure skills use **inline hashtags** format (`#architecture-design`)
5. Follow the standardized [[Person Note Template]]

```bash
# Get commits for a user in last 60 days
gh api "/repos/{owner}/{repo}/commits?author={username}&since=$(date -d '60 days ago' -I)"
```

#### Project Notes Audit

1. Check linked repository for recent activity
2. Update project status (active, maintenance, archived, planning)
3. Verify the project is linked from the projects-index
4. Ensure specs and architecture docs are linked

#### Repository Notes Audit

1. Verify contributor list is current
2. Update technology stack if dependencies changed
3. Check that CI/CD status reflects current state
4. Ensure repository is linked from relevant project notes

#### Design Documents Audit

1. Ensure each spec is linked from its parent project note
2. Ensure each architecture doc is linked from relevant repository notes
3. Update specs-index and architecture-index with new documents
4. Create stub pages for frequently-referenced missing documents
5. Add missing `relates_to` or `implements` relations

#### Audit Summary Report

After completing an audit, generate a summary with:

- Files updated, notes created
- Notes requiring manual review
- Missing links identified and resolved
- Stub pages created

#### Fixing Broken Wiki Links (Obsidian Compatibility)

When wiki links like `[[AI Engineering Team]]` don't resolve in Obsidian:

**Root cause**:
Obsidian resolves `[[Link Text]]` by looking for a file named `Link Text.md`.
Slugified filenames (`ai-engineering-team.md`) may NOT resolve even with
`aliases` in frontmatter - alias resolution can be unreliable.

**Solution**:
Rename files to match their wiki link text exactly:

```bash
# ❌ Broken: ai-engineering-team.md
# ✅ Fixed: AI Engineering Team.md
mv "ai-engineering-team.md" "AI Engineering Team.md"
```

**When creating frequently-linked notes** (teams, indexes, key concepts):

1. Use exact title with spaces in filename:
   `AI Engineering Team.md`
2. Do NOT rely on aliases for link resolution
3. Test the link resolves in Obsidian before committing

**Diagnosing broken links**:

1. Use Obsidian MCP tools to inspect the file exists:
   `obsidian_list_notes_obsidian` with the directory path
2. Check if filename matches the link text exactly
3. If slugified, rename to include spaces

### Topic-Focused Organization

Organize around a specific subject:

1. Find all notes related to topic
2. Map existing relations
3. Identify gaps in the topic graph
4. Suggest new notes to fill gaps
5. Create topic index note

### 8. Convert Session References to Wiki Links

For arc documents that reference sessions by ID, convert them to wiki-style
links pointing to the actual case study notes.

**Before:**

```markdown
- **3bb59894**: Created ADR for simplified data layer access interface
```

**After:**

```markdown
- [[journal/sessions/2025/12/creating-an-adr-for-simplified-data-layer-access|Creating an ADR for Simplified Data Layer Access]]: Created ADR for simplified data layer access interface
```

**Process:**

1. Read the arc document to find session ID patterns (`**xxxxxxxx**:`)
2. For each session ID, search Basic Memory:

   ```python
   mcp__basic-memory__search_notes(
       query="session_id: 3bb59894",
       page_size=2,
       project="main"
   )
   ```

3. Get the **permalink** from the search result (e.g.,
   `journal/sessions/2025/12/creating-an-adr-for-simplified-data-layer-access`)
4. If found, use `edit_note_basic-memory` with `find_replace` operation
5. Replace `**session_id**:
   description` with `[[permalink|Title]]:
   description`
6. If not found, keep the bold session ID format (some sessions may not have
   been documented as individual case studies)

**Tips:**

- Search for session IDs in parallel batches (10-12 at a time) for efficiency
- Use the **permalink** for the link target, **title** for display text
- Format:
  `[[permalink|Title]]` - this works in both Obsidian AND Basic Memory
- Some arcs use table format instead of bullet lists - adjust replacement
  pattern accordingly
- Track found vs not-found to report completion statistics

## Wiki Link Format

Basic Memory and Obsidian use different link formats for different purposes:

### Body/Navigation Links

For clickable links in the note body (outside the Relations section), use:

```markdown
[[permalink|Display Title]]
```

**Example:**

```markdown
- [[journal/sessions/2025/12/creating-an-adr|Creating an ADR]]: Description here
```

- `permalink`:
  The note's path without `.md` (e.g., `case-studies/documentation/my-note`)
- `Display Title`:
  Human-readable title shown in rendered markdown

This format works in **both** Obsidian AND Basic Memory because:

- Obsidian uses the permalink to locate the file
- Basic Memory resolves the note via permalink

**Why title-only links don't work:**

- `[[Creating an ADR]]` fails because filenames are slugified
  (`creating-an-adr.md`)
- Obsidian can't find a file matching the exact title

### Relations Section Links

For semantic relations in the Relations section, use standard wiki-link format:

```markdown
## Relations

- relates_to [[Topic Name]]
- implements [[Parent Concept]]
```

These are standard Obsidian wiki links that Basic Memory parses for the
knowledge graph.

## Best Practices

1. **Work incrementally** - Don't reorganize everything at once
2. **Confirm before changing** - Always ask before moving/editing notes
3. **Preserve permalinks** - Moving is okay, changing permalinks breaks links
4. **Show the graph** - Help user visualize connections
5. **Explain suggestions** - Say why a relation makes sense
6. **Respect user's system** - Enhance their organization, don't impose a new
   one
7. **Use correct link format** - `[[permalink|Title]]` for body links,
   `[[Topic]]` for relations

## Example Conversations

**User:** "Help me organize my notes"

**Claude:**

1. Runs health check on the knowledge base
2. Reports:
   "You have 47 notes.
   I found 12 orphan notes and 3 potential duplicates."
3. Asks:
   "Would you like to start by connecting the orphan notes, or review the
   duplicates first?"

**User:** "Find notes that should be linked to my API design note"

**Claude:**

1. Reads the API design note
2. Searches for related content
3. Suggests:
   "I found 5 notes that could relate:
   - 'REST Best Practices' -> relates-to
   - 'Authentication Flow' -> implements
   - 'Rate Limiting Decision' -> extends Would you like me to add any of these
     relations?"

**User:** "Are there any notes about similar topics?"

**Claude:**

1. Analyzes note titles and content
2. Identifies clusters of similar notes
3. Reports:
   "I found these potential overlaps:
   - 'Auth Flow' and 'Authentication Design' cover similar ground
   - 'DB Schema v1' and 'DB Schema v2' might need a 'supersedes' relation Would
     you like to review any of these?"
