---
name: auglog-documenter
description: Use when documenting Augment CLI sessions as first-person case studies in Basic Memory
---

# Auglog Documenter

Transform Augment CLI sessions into first-person case studies stored in Basic
Memory, making them searchable and connected to other knowledge.

## When to Use

Use this skill when:

- User says "document session [ID]"
- User says "document [category] sessions"
- User wants to create case studies from past Augment CLI work
- User wants to document a multi-session arc

## Prerequisites

The auglog package must be installed:

```bash
cd /mnt/2b20906f-1847-4c8e-94e4-b841290bddc3/imprivata/ai/auglog
uv pip install -e .
```

## Workflow

### 1. Load the Session

```python
from auglog import sessions, output

session = sessions.load("session_id_or_prefix")

# Review the session log
print(output.format_session_log(session))
```

### 2. Determine Session Type

**Single session**:
Most common - one focused task (debugging, writing, etc.)

**Multi-session arc**:
Related sessions that tell a larger story:

- Brainstorm → validate → implement
- Research → design → document
- Debug → fix → test

For arcs, load all related sessions and understand the progression.

### 3. Generate Narrative Content

Write these sections in FIRST PERSON from the user's perspective:

**What I Was Doing** (1-2 sentences)

- Context and goal
- Example:
  "I was trying to debug why ruff and black were giving different results."

**What Happened** (2-3 paragraphs)

- Narrative of the session flow
- Key interactions and turning points
- Use "I asked the agent..." and "The agent suggested..."
- Include specific details from the session

**Key Takeaways** (bullet points)

- What worked well
- What was learned
- Techniques that could help others

### 4. Write to Basic Memory

Use `write_note_basic-memory` to create the case study:

```python
write_note_basic-memory(
    title="Why Ripgrep Smart Case Was Not Working",
    directory="journal/sessions/2025/11",  # Use YYYY/MM from session date
    tags=["case-study", "debugging", "ripgrep", "fish-shell"],
    content=<content>
)
```

#### Single Session Content Template

```markdown
# Title

## Metadata

- session_id: full-session-uuid
- date: YYYY-MM-DD
- exchanges: N
- duration_minutes: N (or "multi-day" for long sessions with gaps)
- category: debugging|documentation|exploration|etc
- type: case-study

## Initial Prompt

> [Exact verbatim text of the user's first message that started the session]

This provides immediate context for what triggered the session.

## What I Was Doing

[1-2 sentences of context beyond the prompt - why this mattered, what led to it]

## What Happened

[2-3 paragraphs narrative with direct quotes woven in]

Include direct excerpts from key moments:

> **Me:** [verbatim user message]
>
> **Agent:** [verbatim agent response, can be abbreviated with [...] for long responses]

The narrative should flow around these excerpts, not just summarize them.

## Key Takeaways

- Point one
- Point two
- Point three

## Notable Exchanges

Include 3-5 pivotal moments with full verbatim text:

### [Descriptive Label - e.g., "The Breakthrough Moment"]

> **Me:** [exact user message]
>
> **Agent:** [exact agent response - include enough to show the substance]

[1-2 sentences explaining why this exchange mattered]

### [Another Key Moment]

> **Me:** [exact text]
>
> **Agent:** [exact text]

[Brief commentary]

## Relations

- demonstrates [[skill-or-technique]]
- involves [[tool-or-technology]]
- produced [[artifact-if-any]]
```

#### Multi-Session Arc Content Template

For arcs, create:

1. Individual case study for each session (in appropriate category)
2. Arc summary that links them together

**Arc Summary Template:**

```markdown
# [Arc Name] Arc

## Overview

[Brief description of the arc and what it accomplished]

## The Sessions

| Session | Category | Exchanges | Duration | Purpose |
| ------- | -------- | --------- | -------- | ------- |
| abc123 | exploration | 50 | 2 hours | Initial brainstorming |
| def456 | investigation | 20 | 30 min | Validating alternatives |
| ghi789 | documentation | 100 | multi-day | Writing final doc |

## Opening Prompts

How each session began:

**Session 1 (abc123):**
> [Exact first message from session 1]

**Session 2 (def456):**
> [Exact first message from session 2]

**Session 3 (ghi789):**
> [Exact first message from session 3]

## The Story

### Phase 1: [Name]

[Narrative of first session with direct excerpts woven in]

> **Me:** [key message from session]
>
> **Agent:** [key response]

[Continue narrative...]

### Phase 2: [Name]

[Narrative with excerpts from second session]

## Pivotal Moments Across the Arc

### [Label - e.g., "When the approach crystallized"]

From session [ID]:

> **Me:** [verbatim]
>
> **Agent:** [verbatim]

[Why this mattered to the arc]

## Key Learnings

1. Learning one
2. Learning two

## Relations

- summarizes [[Individual Case Study 1]]
- summarizes [[Individual Case Study 2]]
- summarizes [[Individual Case Study 3]]
- references [[artifacts-produced]]
```

### 5. Verify in Basic Memory

```python
search_notes_basic-memory(query="case-study session_id:abc123")
```

Or browse:
`journal/sessions/YYYY/MM/`

## Directory Structure

Case studies live in Basic Memory under `journal/`:

```text
journal/
├── sessions/                       # Session case studies organized by date
│   ├── 2025/
│   │   ├── 10/                     # October 2025 sessions
│   │   ├── 11/                     # November 2025 sessions
│   │   └── 12/                     # December 2025 sessions
│   └── 2026/
│       ├── 01/                     # January 2026 sessions
│       └── 02/                     # February 2026 sessions
├── arcs/                           # Multi-session arc summaries
│   └── data-fabric-api-adr-arc.md
└── reviews/                        # Monthly reviews
    └── monthly-review-february-2026.md
```

**Note:** Session directory is determined by the `date` field in Metadata
section (YYYY/MM).

## Available Tools

### From auglog.sessions

```python
from auglog import sessions

# Load a single session
session = sessions.load("abc12345")  # Full ID or prefix

# Load all sessions
all_sessions = sessions.load_all()

# List all session IDs
ids = sessions.list_all()
```

### From auglog.output

```python
from auglog import output

# Format session log for reference while writing
log = output.format_session_log(session)
```

### From auglog.categorizer

```python
from auglog.categorizer import categorize_session

# Get suggested category for a session
category = categorize_session(session)
```

## Finding Sessions to Document

### By Category

```python
from auglog import sessions
from auglog.categorizer import categorize_session

all_sessions = sessions.load_all()
debugging_sessions = [
    s for s in all_sessions
    if categorize_session(s) == "debugging"
]
```

### By Content

```python
# Search for sessions mentioning a topic
for s in sessions.load_all():
    first_msg = s.chat_history[0].exchange.request_message
    if "graphql" in first_msg.lower():
        print(f"{s.session_id[:8]}: {first_msg[:80]}")
```

### By Date

```python
from datetime import datetime, timedelta

recent = [
    s for s in sessions.load_all()
    if s.created > datetime.now() - timedelta(days=7)
]
```

## Tips

1. **Read the full session first** before writing the narrative
2. **Identify the story arc** - problem, investigation, solution
3. **Be specific** - include actual tool names, file names, error messages
4. **First person always** - "I asked", "I noticed", "The agent found"
5. **Highlight the collaboration** - what the human directed vs agent discovered
6. **Include honest assessments** - dead ends and pivots are valuable too
7. **Duration honesty** - use "multi-day" for sessions with overnight gaps
8. **Add relations** - link to skills demonstrated, tools involved, artifacts
   produced
9. **Consider arcs** - if sessions are related, document them as an arc

## Excerpt Guidelines

**Always include the initial prompt verbatim** - this grounds the entire case
study in what actually started the session.

**Use direct quotes liberally** - the actual words reveal nuance that summaries
lose:

- Copy/paste exact text from the session log
- Use `>` blockquote formatting for all excerpts
- Use `[...]` to abbreviate long responses while keeping key content
- Include enough context that excerpts make sense standalone

**Select exchanges that show:**

- The initial framing (always the first prompt)
- Turning points where understanding shifted
- Moments of confusion or course correction
- The breakthrough or resolution
- Interesting agent reasoning or tool usage

**Weave excerpts into narrative** - don't just dump quotes.
Introduce them:

- "When I asked about X, the response surprised me:"
- "The key insight came when the agent noticed:"
- "After several attempts, I tried a different approach:"

**Length guidance:**

- Initial prompt:
  always full verbatim
- Notable exchanges:
  3-5 per session, enough text to show substance
- Agent responses:
  can abbreviate with `[...]` but keep the meat
