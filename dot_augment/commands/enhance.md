---
description: Enhance raw notes with semantic structure, observations, and relations
argument-hint: [<note-name>|--inbox|--recent]
allowed-tools: search_notes_basic-memory, read_note_basic-memory, edit_note_basic-memory, build_context_basic-memory, recent_activity_basic-memory
---

# Enhance

Transform raw or quick-captured notes into well-structured semantic notes with observations, tags, and relations.

## IMPORTANT: Use Basic Memory Tools

**ALWAYS use Basic Memory MCP tools.** Do NOT use filesystem tools.

| Operation | Use This Tool |
|-----------|---------------|
| Find notes | `search_notes_basic-memory(query="...")` |
| Read note | `read_note_basic-memory(identifier="...")` |
| Edit note | `edit_note_basic-memory(identifier="...", operation="...", ...)` |
| Get context | `build_context_basic-memory(url="memory://...", depth=1)` |
| Recent notes | `recent_activity_basic-memory(timeframe="today")` |

## Subcommands

| Command | Description |
|---------|-------------|
| `/enhance <note>` | Enhance a specific note by name |
| `/enhance --inbox` | Process all notes tagged `#raw` |
| `/enhance --recent` | Enhance notes from today |

## Your Task

### `/enhance <note>` - Enhance Specific Note

1. **Find and read the note:**
```python
search_notes_basic-memory(query="<note>")
read_note_basic-memory(identifier="<found-path>")
```

2. **Analyze the content:**
   - Identify key concepts and entities
   - Extract facts, decisions, insights
   - Find potential connections to existing knowledge

3. **Build context for relations:**
```python
build_context_basic-memory(url="memory://related-topic", depth=1)
```

4. **Present enhancement plan:**
```
## 🔍 Enhancing: <Note Title>

**Current state:** Raw note with minimal structure

**Proposed enhancements:**

### Observations to add:
- [insight] <key insight from content> #tag
- [decision] <decision mentioned> #tag
- [fact] <important fact> #tag

### Relations to add:
- relates_to [[Related Note 1]]
- builds_on [[Related Note 2]]
- informs [[Related Note 3]]

### Tags to add:
#topic1 #topic2 #topic3

---

Apply these enhancements? (yes/no/edit)
```

5. **Apply enhancements on approval:**
```python
edit_note_basic-memory(
    identifier="<note-path>",
    operation="replace_section",
    section="Observations",
    content="- [insight] ... #tag\n- [decision] ... #tag"
)
edit_note_basic-memory(
    identifier="<note-path>",
    operation="append",
    content="\n## Relations\n\n- relates_to [[Note]]\n"
)
```

6. **Confirm completion:**
```
✅ Enhanced: **<Note Title>**
   Added: 3 observations, 2 relations, 4 tags
   Location: <path>
```

### `/enhance --inbox` - Process Raw Notes

1. **Find all raw notes:**
```python
search_notes_basic-memory(query="#raw")
```

2. **List notes to process:**
```
## 📥 Inbox: X notes to enhance

1. **Quick thought on caching** - notes/quick-thought-on-caching.md
2. **Meeting standup** - notes/meetings/meeting-standup.md
3. **API idea** - notes/ideas/api-idea.md

Process all? Or pick specific numbers.
```

3. **Process each note** using the single-note workflow above

4. **Remove `#raw` tag** after enhancement

### `/enhance --recent` - Today's Notes

1. **Get recent activity:**
```python
recent_activity_basic-memory(timeframe="today")
```

2. **Filter to notes that need enhancement** (missing observations/relations)

3. **Process using inbox workflow**

## Enhancement Patterns

### For Thoughts/Ideas
- Extract the core insight as an observation
- Identify what it relates to
- Tag with topic areas

### For Meeting Notes
- Extract decisions as `[decision]` observations
- Extract action items as `[action]` observations
- Link to projects, people, previous meetings

### For Todos (if raw)
- Ensure acceptance criteria exist
- Add priority observation
- Link to related tasks or epics

## Observation Categories

| Category | Use For |
|----------|---------|
| `[insight]` | Key realizations or learnings |
| `[decision]` | Choices made |
| `[fact]` | Important information |
| `[action]` | Things to do |
| `[question]` | Open questions |
| `[risk]` | Concerns or issues |
| `[pattern]` | Recurring themes |

## Examples

```
/enhance "caching thoughts"
→ Enhances specific note with observations and relations

/enhance --inbox
→ Shows all #raw notes, processes them one by one

/enhance --recent
→ Enhances today's notes that need structure
```

## Philosophy

Enhancement is about **adding semantic value** without changing the original content. The goal is to make notes:
- Searchable via semantic observations
- Connected via relations
- Discoverable via tags

Always preserve the original content - add structure around it.

