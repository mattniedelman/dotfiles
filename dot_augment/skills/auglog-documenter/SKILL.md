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
---
title: Title
type: note
permalink: main/journal/sessions/YYYY/MM/title-slug
tags:
- case-study
- [category]
- [relevant-tags]
session_id: short-session-id
date: YYYY-MM-DD
exchanges: N
category: debugging|documentation|exploration|etc
---

# Title

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

For arcs, create an arc summary in `journal/arcs/`.
Individual session case studies are optional - the arc note can stand alone.

**Arc Summary Template:**

```markdown
---
title: Multi-Session Arc: [Arc Name]
type: note
permalink: main/journal/arcs/multi-session-arc-[name-slug]
tags:
- multi-session-arc
- [pattern-type]
- [relevant-tags]
---

# Multi-Session Arc: [Arc Name]

[One sentence describing what the arc accomplished]

## Arc Metadata

- arc_type: [brainstorm-to-document | plan-create-refine | investigation | etc]
- sessions: N
- total_exchanges: N
- date_range: YYYY-MM-DD to YYYY-MM-DD
- outcome: [What was produced or resolved]

---

## Session Timeline

Session IDs link to their case study notes using wiki link format:
`[[Case Study Title|short_id]]`

### Session 1: [[Case Study Title|short_id]] ([N] exch) - YYYY-MM-DD HH:MM
**[Role - e.g., Spec Brainstorming]**

> [First user message - verbatim or summarized if slashcommand]

[1-2 sentences describing what this session accomplished in the arc]

### Session 2: [[Another Case Study|short_id]] ([N] exch) - YYYY-MM-DD HH:MM
**[Role - e.g., Technology Exploration]**

> [First user message]

[Brief description]

### Session 3: [[Third Case Study|short_id]] ([N] exch) - YYYY-MM-DD HH:MM
**[Role - e.g., ADR Creation]**

> [First user message]

[Brief description]

---

## Arc Pattern

**[Pattern Name]** - [Brief description of the pattern]

[Note any interesting aspects like same-day clustering, parallel deep dives, etc]

## Key Artifacts

- [Artifact 1 produced]
- [Artifact 2 produced]

## Relations

- demonstrates [[Pattern or Process]]
- involves [[Technology or Tool]]
- produces [[Artifact]]
```

**Key differences from individual case studies:**

1. **Location**:
   `journal/arcs/` not `journal/sessions/YYYY/MM/`
2. **Focus**:
   Session roles and progression, not detailed narrative
3. **Verbatim prompts**:
   First message from each session, not full exchanges
4. **Arc pattern**:
   Name and describe the pattern for future reference

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

**Note:** Session directory is determined by the `date` field in frontmatter
(YYYY/MM).

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
from datetime import datetime, timedelta, timezone

recent = [
    s for s in sessions.load_all()
    if s.created > datetime.now(timezone.utc) - timedelta(days=7)
]
```

## Discovering Multi-Session Arcs

Arcs are 2-4+ sessions focused on a specific task - not just "all sessions about
a topic" but sessions that form a coherent unit of work with progression.

### Arc Discovery Strategies

Use ALL of these strategies to find complete arcs:

#### 1. Artifact References

Sessions that reference specs, ADRs, or artifacts created in earlier sessions:

```python
# Find sessions referencing prior work
artifact_patterns = [
    'considering the', 'based on the', 'the spec', 'the adr',
    'we discussed', 'we created', 'prior work', 'following up'
]
for s in all_sessions:
    first_msg = s.chat_history[0].exchange.request_message.lower()
    if any(p in first_msg for p in artifact_patterns):
        print(f"{s.session_id[:8]} | {s.created} | {first_msg[:80]}")
```

#### 2. Brainstorm Sessions (Arc Starters)

Sessions using `/brainstorm` often CREATE the artifacts other sessions
reference:

```python
# Find brainstorm sessions - these often START arcs
for s in all_sessions:
    first_msg = s.chat_history[0].exchange.request_message
    if '# Brainstorm' in first_msg or 'brainstorm' in first_msg.lower()[:100]:
        print(f"{s.session_id[:8]} | {s.created} | {len(s.chat_history)} exch")
```

#### 3. Continuation Signals

Sessions explicitly continuing prior work:

```python
continuation_signals = [
    'continue', 'resume', 'memory://', '## TODO', 'pick up where',
    'following up', 'as we discussed'
]
for s in all_sessions:
    first_msg = s.chat_history[0].exchange.request_message.lower()
    if any(sig in first_msg for sig in continuation_signals):
        print(f"{s.session_id[:8]} references prior work")
```

#### 4. Temporal Clustering

Multiple sessions on the same day working on related topics:

```python
from collections import defaultdict

# Group sessions by date
by_date = defaultdict(list)
for s in all_sessions:
    date_str = s.created.strftime('%Y-%m-%d')
    first_msg = s.chat_history[0].exchange.request_message[:100]
    by_date[date_str].append((s.session_id[:8], len(s.chat_history), first_msg))

# Find dates with multiple related sessions
for date, sessions_list in by_date.items():
    if len(sessions_list) >= 3:
        print(f"\n=== {date} ({len(sessions_list)} sessions) ===")
        for sid, exch, msg in sessions_list:
            print(f"  {sid} | {exch:3} | {msg[:60]}")
```

#### 5. Response Text Analysis

Check agent responses for artifact mentions (catches indirect references):

```python
# Search both user messages AND agent responses
for s in all_sessions:
    all_text = ''
    for exch in s.chat_history[:5]:
        all_text += exch.exchange.request_message.lower() + ' '
        if exch.exchange.response_text:
            all_text += exch.exchange.response_text[:500].lower() + ' '

    if 'data fabric' in all_text:  # or other artifact name
        print(f"{s.session_id[:8]} mentions artifact")
```

### Common Arc Patterns

| Pattern | Description | Example |
|---------|-------------|---------|
| Brainstorm -> Build -> Document | Spec creation, implementation, then ADR | Data Fabric |
| Plan -> Create -> Refine | Planning session, main work, follow-up polish | API Versioning ADR |
| Context -> Debug -> Document | Investigation with memory:// references | Bifrost Caching |
| Test -> Debug -> Fix | Iterative development with issues | Docs Crawler |
| Systematic Triage | Same-day multi-session focused effort | Linting Review |
| Progressive Integration | Spread over time, building on prior work | Basic Memory MCP |

### Arc Documentation Workflow

1. **Find the precursor session** - Often a brainstorm or planning session
2. **Map the full timeline** - All sessions referencing the artifact/work
3. **Identify session roles** - Which created, which extended, which refined
4. **Note parallel deep dives** - Sessions that branch off for investigation
5. **Document in journal/arcs/** - Separate from individual session case studies

### Arc Note Location

Multi-session arcs go in `journal/arcs/`, NOT in `journal/sessions/YYYY/MM/`:

```text
journal/
├── sessions/           # Individual case studies by date
│   └── 2026/02/
└── arcs/               # Multi-session arc summaries
    ├── multi-session-arc-data-fabric-architecture.md
    └── multi-session-arcs-index.md
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
