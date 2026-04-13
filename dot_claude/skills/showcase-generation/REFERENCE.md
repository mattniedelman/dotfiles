# Showcase Generation - Reference Templates

## Directory Structure

```text
showcase/
├── README.md                    # Overview and navigation
├── philosophy/
│   ├── why-this-works.md        # Core design rationale
│   └── approach.md              # How Matt works with AI
├── configuration/
│   ├── rules/                   # Rule annotations
│   ├── skills/                  # Skill annotations
│   ├── agents/                  # Agent annotations
│   ├── hooks/                   # Hook annotations
│   └── commands/                # Command annotations
└── case-studies/
    ├── {arc-name}/
    │   ├── README.md            # Main narrative
    │   ├── arc.md               # Arc metadata
    │   └── sessions/
    │       ├── 01-{name}.md
    │       └── 02-{name}.md
    └── ...
```

## Full-Depth Annotation Template (100-200 lines)

For core workflow items (top 6-8 skills, primary agents, key hooks).

```markdown
# {Item Name}

## Why I Created This

{The specific problem that prompted creation - not a generic use case.
What was happening before this existed? What failure mode was it addressing?}

## How It Works

### {Phase or Component 1}

{Detailed description of what happens, with specific examples from actual use.}

### {Phase or Component 2}

{Continue for each major component.}

## Key Design Decisions

- **{Decision}**: {Why this choice over alternatives.
  What was considered and rejected?}
- **{Decision}**: {Rationale from experience.}

## Integration Points

- **{Related item}**: {How they interact.}
- **{Related item}**: {How they interact.}

## Example in Action

{Specific example from an actual session, with quotes if available.}

> **Me:** {actual prompt or similar}
>
> {What happened as a result}

## Evolution Notes

{How this changed over time based on usage.
What was the original version?
What prompted each revision?}
```

## Summary Annotation Template (30-50 lines)

For less critical items (utility skills, simple hooks, domain-specific agents).

```markdown
# {Item Name}

**Purpose:** {1-2 sentences describing what this does and when it triggers.}

## Key Points

- {Most important characteristic}
- {Second characteristic}
- {Third characteristic}
- {Any non-obvious behavior}

## Notable Choices

- **{Choice}**: {Brief rationale}

## Related Items

- **{Related}**: {Relationship}
```

## Execution Modes

### Interactive Mode (Preferred for Philosophy/Overview)

In interactive mode, the showcase gets Matt's specific voice and insights.
Content produced this way includes:
- Specific quotes from past sessions
- Named patterns and concepts
- Counter-intuitive discoveries
- Evolution notes from experience

Use for:
philosophy docs, overview pages, high-value case studies

### Autonomous Mode (Acceptable for Structured Content)

In autonomous mode, the showcase can generate structured content from Basic
Memory arc notes and session data without interactive dialogue.
Acceptable for:
case study structure, arc metadata, session summaries.

**When running autonomously:**

1. Complete the planning phase (SKILL.md Steps 1-5) before generating
2. Pull content from Basic Memory arc/session notes
3. Include actual quotes from session logs
4. Mark sections needing interactive enrichment:
   ```
   <!-- TODO: Interactive enrichment needed -->
   <!-- Mechanism described but Matt's specific insight missing -->
   ```
5. Flag gaps explicitly rather than filling with generic content

## Source Link Mapping

| Content Type | Basic Memory Source |
|-------------|---------------------|
| Case study arcs | `journal/arcs/multi-session-arc-{name}` |
| Session details | `journal/sessions/YYYY/MM/{session-name}` |
| Learning notes | `learnings/{topic}` |
| Design decisions | `artifacts/specs/{feature}` |

## Pulling Content from Basic Memory

```python
# Find arc notes
search_notes(query="multi-session arc", tags=["arc"])  # Basic Memory MCP

# Get all arcs
build_context(url="memory://journal/arcs/*", depth=1)  # Basic Memory MCP

# Read a specific arc
read_note(identifier="journal/arcs/arc-name")  # Basic Memory MCP

# Find session notes for an arc
build_context(
    url="memory://journal/sessions/2025/11/*",
    depth=1,
)  # Basic Memory MCP
```

## Markdownlint Quick Reference

Common issues and fixes for showcase content:

| Rule | Problem | Fix |
|------|---------|-----|
| MD028 | Blank line between blockquotes | Use `>` continuation line |
| MD025 | H1 in blockquote | Replace with prose description |
| MD032 | List inside blockquote | Restructure to prose or separate |
| MD013 | Long lines in code blocks | Exempt code blocks from line length |
| MD041 | No H1 at top | Ensure every file starts with `#` |
