---
name: brainstorming
description: Use when doing any creative work - creating features, building components, adding functionality, or modifying behavior; explores user intent, requirements and design before implementation
---

# Brainstorming Ideas Into Designs

## Overview

Help turn ideas into fully formed designs and specs through natural
collaborative dialogue.

Start by understanding the current project context, then ask questions one at a
time to refine the idea.
Once you understand what you're building, present the design in small sections
(200-300 words), checking after each section whether it looks right so far.

## The Process

**Understanding the idea:**

- Check out the current project state first (files, docs, recent commits)
- Ask exactly ONE question per message - never bundle multiple questions
  together
- Prefer multiple choice questions when possible, but open-ended is fine too
- If a topic needs more exploration, break it into separate messages with one
  question each
- Focus on understanding:
  purpose, constraints, success criteria

**Exploring approaches:**

- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Presenting the design:**

- Once you believe you understand what you're building, present the design
- Break it into sections of 200-300 words
- Ask after each section whether it looks right so far
- Cover:
  architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

## After the Design

**Documentation:** Save the validated design to Basic Memory.

**CRITICAL:** Always use `write_note_basic-memory` - NEVER use `save-file` or
write design documents to local filesystem folders.

```python
write_note_basic - memory(
    title="Design: <topic>",
    content="[design content]",
    directory="artifacts/specs",  # Basic Memory directory, not local path
    tags=["design", "spec", "<topic-tags>"],
)
```

The note should follow this structure:

```markdown
# Design: <Topic>

## Summary
[2-3 sentence overview of what we're building]

## Requirements
[Key requirements discovered during brainstorming]

## Architecture
[High-level architecture decisions]

## Components
[Key components and their responsibilities]

## Data Flow
[How data moves through the system]

## Error Handling
[Error handling approach]

## Testing Strategy
[How this will be tested]

## Open Questions
[Any remaining uncertainties]

## Observations

- [decision] Architecture choice made #design
- [requirement] Key requirement identified
- [constraint] Important constraint discovered

## Relations

- implements [[Related Feature]]
- relates_to [[Related System]]
- informs [[Implementation Plan]]
```

**Implementation (if continuing):**

- Ask:
  "Ready to set up for implementation?"
- Use superpowers:using-git-worktrees to create isolated workspace
- Use superpowers:writing-plans to create detailed implementation plan

## Ambiguity Detection (MANDATORY)

Before proceeding to design, check for ambiguity:

| Ambiguity Type | Detection | Resolution |
|----------------|-----------|------------|
| **Scope ambiguity** | "What exactly should this do?" | List concrete behaviors |
| **Technical ambiguity** | "How should this integrate?" | Identify touchpoints |
| **Priority ambiguity** | "What's most important?" | Rank requirements |
| **Constraint ambiguity** | "What can't change?" | List hard constraints |
| **Success ambiguity** | "How do we know it works?" | Define acceptance criteria |

**Ambiguity threshold:** If >2 ambiguous items, STOP and clarify before
proceeding.

## Discussion-First Gate (DAIC Pattern)

Before ANY implementation:

```text
┌─────────────────────────────────────────┐
│ Implementation Plan                     │
│                                         │
│ Goal: [plain English description]       │
│                                         │
│ Steps:                                  │
│   1. [Step]                             │
│   2. [Step]                             │
│   3. [Step]                             │
│                                         │
│ Files to modify: [list]                 │
│ Tests to add: [list]                    │
│                                         │
│ Does this match your intentions?        │
└─────────────────────────────────────────┘

⏸️ STOP AND WAIT FOR USER CONFIRMATION

Only proceed to implementation after explicit approval.
```

## Key Principles

- **CRITICAL:
  One question at a time** - Never ask multiple questions in a single message.
  If you need to explore multiple topics, send separate messages for each
  question.
  This is non-negotiable.
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense
- **Ambiguity gating** - Don't proceed with >2 unresolved ambiguities

## Workflow Integration

**Phase:** EXPLORE

**Inputs:**

- User request or idea
- Existing context from `continue-conversation` if resuming

**Outputs:**

- Spec saved to `artifacts/specs/{feature}.md` in Basic Memory

**Pre-check:**

- Is there existing work on this topic?
  Check Basic Memory first.

**Handoff:** When brainstorming is complete:

1. Save spec to Basic Memory with `write_note_basic-memory`
2. Declare:
   "**Phase Complete:
   EXPLORE -> PLAN**"
3. Suggest:
   "Ready for `writing-plans` to create implementation plan"

**Related Skills:**

- `deep-dive` - For more intensive exploration
- `storm` - For research with multiple perspectives
- `writing-plans` - Next phase (PLAN)
- `spec-driven-development` - If spec already exists
