---
name: showcase-generation
description: Use when generating or updating annotated files for the showcase repository
---

# Showcase Generation

## Perspective: First-Person from Matt's POV

All showcase content is written from **Matt's perspective as the developer** who
configured this system.
The AI is a tool he uses, not the narrator.

### Correct Framing

| Context | Correct | Incorrect |
| --- | --- | --- |
| Describing a skill | "I use this skill to ensure the AI writes tests first" | "I invoke this skill to prevent my most common failure mode" |
| Describing a rule | "This rule prevents the AI from committing without my permission" | "I never commit without explicit authorization" |
| Describing a hook | "This hook catches lint errors before I see the AI's output" | "This hook ensures I fix lint errors" |
| Describing an agent | "I dispatch this agent when I need focused code review" | "I review code when the user asks" |

### Key Distinction

- **"I"** = Matt (the developer who configured the system)
- **"The AI"** or **"the agent"** = the AI assistant being configured
- **"The skill/rule/hook"** = configuration that shapes AI behavior

## Prose Style

**Matter-of-fact prose only.** No humanizing the system, no evaluative language.

| Avoid | Use Instead |
| --- | --- |
| "amazing", "inspiring", "incredible" | (just describe what it does) |
| "This elegant solution..." | "This approach..." |
| "The AI brilliantly handles..." | "The AI handles..." |
| "greatly improved", "much better" | Specific measurable claims or nothing |

## Model Names

Use consistent model identifiers (as they appear in agent frontmatter):

| Correct | Incorrect |
| --- | --- |
| `sonnet4.5` | `claude-3-5-sonnet`, `sonnet-4.5`, `claude-sonnet` |
| `opus4.5` | `opus-4.5`, `claude-opus` |
| `haiku4.5` | `haiku-4.5`, `claude-haiku` |

**Avoid `inherit`** - every agent should explicitly declare its model.
`inherit` creates unpredictable behavior when the user's selected model doesn't
match the agent's capability requirements.

## Design Philosophy

**Experimentation is encouraged.** It's fine to create agents proactively and
see how often they get used (explicitly or auto-selected by Augment).
Low-use agents can be refined, merged, or removed.
Low-cost experimentation beats over-planning.

## Case Study Structure

Each case study folder requires three components:

```text
case-studies/{case-name}/
├── README.md           # Main narrative (100-200 lines)
├── arc.md              # Arc metadata and session timeline
└── sessions/           # Individual session summaries
    ├── 01-{session-name}.md
    ├── 02-{session-name}.md
    └── ...
```

### README.md (Main Narrative)

The primary document.
Include:

- **Overview table**:
  Sessions, total exchanges, date range, pattern, artifacts
- **The Problem**:
  What I was trying to solve
- **Session Timeline**:
  Brief summary of each session with quotes
- **What Made This Work**:
  Patterns that contributed to success
- **Key Takeaways**:
  Bullets summarizing learnings

### arc.md (Arc Metadata)

Structured metadata pulled from Basic Memory arc notes:

```markdown
# Multi-Session Arc: {Name}

{One-line description}

## Arc Metadata

- arc_type: {brainstorm|investigation|implementation|documentation}
- sessions: {count}
- total_exchanges: {total}
- date_range: {YYYY-MM-DD to YYYY-MM-DD}
- outcome: {brief outcome}

## Session Timeline

| # | Session | Exchanges | Date | Focus |
|---|---------|-----------|------|-------|
| 1 | {name} | {count} | {date} | {focus} |

## Arc Pattern

{Pattern description, e.g., "Brainstorm → Build → Document"}

## Notable Characteristics

- {characteristic 1}
- {characteristic 2}

## Key Artifacts

- {artifact 1}
- {artifact 2}
```

### Session Files (Individual Details)

Each session file provides substantive detail beyond what's in the README.
Include:

- **Metadata**:
  session_id, date, exchanges, category
- **Initial Prompt**:
  The actual prompt (or summary if long)
- **What I Was Doing**:
  Context for why this session happened
- **What Happened**:
  Detailed subsections describing the work
- **Key Takeaways**:
  Session-specific learnings

**Session file substance matters.** Include:

- Actual quotes from the conversation (with `> **Me:**` and `> **Agent:**`
  format)
- Structured "What Happened" subsections describing phases of work
- Specific details that add value beyond the README summary

### Single-Session Arcs

Single-session arcs are valid case studies.
Marathon sessions (300+ exchanges) often contain enough material for a complete
case study with iterative refinement within one conversation.

## Markdownlint Patterns

### Consecutive Blockquotes (MD028)

**Wrong** - blank line between blockquotes:

```markdown
> **Me:** first quote

> **Agent:** second quote
```

**Correct** - join with `>` continuation:

```markdown
> **Me:** first quote
>
> **Agent:** second quote
```

### Headers in Blockquotes (MD025)

**Wrong** - markdown header inside blockquote:

```markdown
> # Ralph Wiggum Development Flow
>
> Execute the workflow...
```

**Correct** - describe instead of quoting the header:

```markdown
The Ralph Wiggum system prompt followed by the task:

> Improve logging throughout this project with the following requirements...
```

### Lists in Blockquotes (MD032)

**Wrong** - list directly in blockquote without spacing:

```markdown
> **Log Level Guidelines:**
> - ERROR: Exceptions
> - WARNING: Recoverable errors
```

**Correct** - restructure to prose or separate from quote:

```markdown
Log Level Guidelines: ERROR for exceptions, WARNING for recoverable errors,
INFO for request/response summaries, DEBUG for detailed execution flow.
```

## Content Sourcing

Pull case study content from Basic Memory:

1. **Arc notes**:
   `journal/arcs/multi-session-arc-{name}`
2. **Session notes**:
   `journal/sessions/YYYY/MM/{session-name}`
3. **Learning notes**:
   `learnings/{topic}`

Include actual quotes and specific details from these sources rather than
generic summaries.

## File Types

### Full Depth Annotations (100-200 lines)

For core workflow items.
Include:

- **Why I Created This**:
  My problem and how this solves it
- **How It Works**:
  Section-by-section breakdown
- **Key Design Decisions**:
  Why I chose this approach
- **Integration Points**:
  How it connects to other config
- **Example in Action**:
  Real scenario showing the behavior

### Summary Annotations (30-60 lines)

For utility/domain-specific items.
Include:

- **Purpose**:
  1-2 sentences on what it does
- **Key Points**:
  3-5 bullets of main behaviors
- **Notable Choices**:
  1-2 design decisions
- **Related Items**:
  Links to related config

## Directory Structure

```text
matt-niedelman-imprivata/     # Repository root (no intermediate showcase/)
├── README.md                 # Entry point, "My Setup" section
├── .markdownlint.json        # Lint config for showcase
├── docs/
│   ├── plans/                # Implementation plans
│   ├── philosophy.md         # Operating philosophy
│   ├── architecture.md       # Configuration by purpose
│   └── getting-started.md    # How to adopt these patterns
├── case-studies/             # Narrative walkthroughs
│   └── {case-name}/
│       ├── README.md         # Main narrative (100-200 lines)
│       ├── arc.md            # Arc metadata and session timeline
│       └── sessions/         # Individual session summaries
│           └── 01-{session-name}.md
├── reference/                # Annotated config files
│   ├── rules/
│   │   ├── README.md         # Lists all rules
│   │   └── {rule}-annotated.md
│   ├── agents/
│   │   ├── README.md         # Lists all agents
│   │   └── {agent}-annotated.md
│   ├── hooks/
│   │   ├── README.md         # Lists all hooks
│   │   └── {hook}-annotated.md
│   ├── skills/
│   │   ├── README.md         # Lists all skills
│   │   └── {skill}-annotated.md
│   ├── commands/
│   │   ├── README.md         # Lists all commands
│   │   └── {command}-annotated.md
│   ├── mcp-servers/
│   │   ├── README.md         # Lists all MCP servers
│   │   └── {server}.md       # Server documentation
│   └── ast-grep/
│       ├── README.md
│       └── example-rules.md
└── specs/                    # Feature specifications
```

## Source Links

Every annotated file must link to its source in the dotfiles submodule:

```markdown
# {Name} - Annotated

**Source:** [{filename}](../../dotfiles/dot_augment/{category}/{filename})
```

- **Not a blockquote** - plain bold text to avoid MD028 errors
- **Relative path** - from `reference/{category}/` to `dotfiles/dot_augment/`
- **Category mapping:**
  - Rules:
    `dotfiles/dot_augment/rules/{name}.md`
  - Agents:
    `dotfiles/dot_augment/agents/{name}.md`
  - Hooks:
    `dotfiles/dot_augment/hooks/executable_{name}.{sh|py}`
  - Skills:
    `dotfiles/dot_augment/skills/{name}/SKILL.md`
  - Commands:
    `dotfiles/dot_augment/commands/{name}.md`
  - MCP Servers:
    No source link (configured in settings.json, not individual files)
  - ast-grep:
    `dotfiles/private_dot_config/ast-grep/`
  - ruff:
    `dotfiles/private_dot_config/ruff/`

### Hook Implementation

**Hook files must have `.sh` extension** but can use any interpreter via the
shebang line (Python, Node, Ruby, Go, etc.).
For complex Python hooks, use cchooks with `augment_adapter.py`.

Alternative SDKs:
Go (cc-tools), TypeScript (claude-hooks), PHP (claude-code-hooks-sdk).

### Hook Event Types

Use consistent event names (PascalCase as they appear in settings.json):

| Event | When | Can Block |
|-------|------|-----------|
| `SessionStart` | Conversation begins | No |
| `SessionEnd` | Session ends | No |
| `PreToolUse` | Before tool execution | Yes (exit 2) |
| `PostToolUse` | After tool execution | No |
| `Stop` | Agent stops responding | Yes (exit 2) |

### Path References in Content

When referencing config paths in prose or tables, link to the dotfiles
submodule:

| Original Path | Link Format |
|---------------|-------------|
| `~/.config/ast-grep/rules/` | `[~/.config/ast-grep/rules/](../../dotfiles/private_dot_config/ast-grep/rules/)` |
| `~/.config/ruff/ruff.toml` | `[ruff.toml](../../dotfiles/private_dot_config/ruff/ruff.toml)` |
| `~/.augment/agents/` | `[~/.augment/agents/](../../dotfiles/dot_augment/agents/)` |

**Shorten link text in tables** to stay under 120 characters per line.

## Annotation Template: Full Depth

```markdown
# {Name} - Annotated

**Source:** [{filename}](../../dotfiles/dot_augment/{category}/{filename})

## Why I Created This

{1-2 paragraphs explaining the problem I faced and why I built this solution}

## How It Works

### {Section 1}

{Explanation of what this section does and why I structured it this way}

## Key Design Decisions

### {Decision 1}

**Choice:** {What I chose}
**Alternatives:** {What I considered}
**Rationale:** {Why this approach won}

## Integration Points

- Links to {related-rule} for {reason}
- Works with {agent-name} during {workflow}

## Example in Action

{Concrete scenario showing this config affecting AI behavior}
```

## Annotation Template: Summary

```markdown
# {Name}

## Purpose

{1-2 sentence description of what this does}

## Key Points

- {Main behavior 1}
- {Main behavior 2}
- {Main behavior 3}

## Notable Choices

- {Design decision and brief rationale}

## Related Items

- [{related-item}](./{path}) - {why related}
```

## Quality Checklist

Before completing any showcase file:

- [ ] Perspective is from Matt's POV (not the AI's)
- [ ] "I" refers to Matt, "the AI/agent" refers to the assistant
- [ ] Prose is matter-of-fact (no "amazing", "inspiring", etc.)
- [ ] File passes markdownlint with showcase config
- [ ] Consecutive blockquotes use `>` continuation (not blank lines)
- [ ] No markdown headers inside blockquotes
- [ ] Links to related items are valid
- [ ] Line count is appropriate (full:
  100-200, summary:
  30-60)
- [ ] Session files include actual quotes and substantive detail
