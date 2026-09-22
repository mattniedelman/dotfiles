---
name: note
description: Use when user wants to quickly capture a thought, idea, task, or meeting note to Basic Memory - fast capture with sensible defaults, no filesystem writes
---

# Note

Quickly capture any type of note to Basic Memory.
Fast capture with sensible defaults.

**ALWAYS use Basic Memory MCP tools to create notes.
NEVER use filesystem tools.**

## Note Types

| Type | Directory | Use Case |
| ---- | --------- | -------- |
| `thought` | `_meta/working/` | Default - quick thoughts, observations |
| `todo` | `planning/tasks/backlog/` | Tasks and action items |
| `idea` | `_meta/working/ideas/` | Ideas to explore later |
| `meeting` | `_meta/working/meetings/` | Quick meeting notes |

## When to Use

- User says "note that...", "capture this", "save this thought"
- User invokes `/note <content>`
- User wants to quickly jot something down without discussion

## Process

Parse from user input or arguments:

- **Content**:
  The main text
- **Type**:
  Look for `type:todo`, `type:idea`, etc. (default:
  `thought`)
- **Priority**:
  For todos, look for `priority:P0`, etc. (default:
  P2)
- **Project**:
  Look for `project:<name>` (optional)

**Type inference** - If no explicit type, infer from content:

- Contains "fix", "add", "implement", "update", "refactor" -> `todo`
- Contains "what if", "maybe", "could we", "idea:" -> `idea`
- Contains "meeting", "standup", "retro", "sync" -> `meeting`
- Otherwise -> `thought`

Create the note immediately with appropriate template.
No questions asked.

Brief confirmation:
note title, type, and location.

## Note Creation

```python
# Basic Memory MCP
write_note(
    title="<inferred title from content>",
    content="[note content]",
    directory="<type-appropriate directory>",
    tags=["<type>", "<project if provided>"],
)
```
