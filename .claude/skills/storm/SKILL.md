---
name: storm
description: Use when deep research is needed from multiple expert perspectives - comprehensive analysis, architectural decisions, exploring complex topics, or synthesizing information with citations
---

# STORM Research

This skill implements the STORM pattern (Synthesis of Topic Outlines through
Retrieval and Multi-perspective Question Asking) from Stanford for deep,
comprehensive research.

## When to Use

Use this skill when:

- User asks to research, investigate, or explore a topic in depth
- User wants comprehensive analysis from multiple viewpoints
- User needs context before making architectural or design decisions
- Complex topics requiring expert perspectives (security, performance, UX, etc.)
- Phrases like "research this", "deep dive into", "explore options for"

## Output Storage

**CRITICAL:** All STORM research output MUST be saved to Basic Memory using the
`write_note` tool (Basic Memory MCP).
NEVER write files to the local filesystem.

## Related Skills

**Use `deep-research` first if:** You need to understand existing code or
systems before researching external options.
STORM assumes you know what you have; deep-research builds that understanding.

**Use `deep-research` after if:** STORM research concludes you need deeper
understanding of a specific component before deciding.

## STORM Process Overview

```text
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 1: Perspective Discovery │
│ → Survey similar topics to identify relevant expert viewpoints │
├─────────────────────────────────────────────────────────────────┤
│ PHASE 2: Multi-Perspective Research (PARALLEL) │
│ → Spawn subagents per perspective for simulated conversations │
├─────────────────────────────────────────────────────────────────┤
│ PHASE 3: Outline Synthesis │
│ → Merge insights into hierarchical outline by theme │
├─────────────────────────────────────────────────────────────────┤
│ PHASE 4: Report Generation │
│ → Generate report with citations, save to Basic Memory │
└─────────────────────────────────────────────────────────────────┘
```

## Phase 1: Perspective Discovery

### Goal

Identify 3-5 expert perspectives relevant to the topic by surveying existing
knowledge.

### Process

1. **Check Basic Memory** for existing context:

```python
# Basic Memory MCP
search_notes(query="topic keywords")
build_context(url="memory://related-topic", depth=2)
```

2. **Survey similar topics** via web search:

```python
WebSearch(query="[topic] best practices expert perspectives")
WebSearch(query="[topic] considerations trade-offs")
```

3. **Extract perspectives** from search results.
   Look for different professional roles discussing the topic, recurring
   concerns or focus areas, and conflicting viewpoints or trade-offs.

4. **Define perspectives** based on what you discovered.
   These are NOT hard-coded - they emerge from the topic research.
   Document them:

```markdown
## Discovered Perspectives

For topic: "[TOPIC]"

| Perspective | Focus Areas | Key Questions |
|-------------|-------------|---------------|
| [Role found in sources] | [Their concerns] | [Questions they'd ask] |
| [Another role] | [Their concerns] | [Questions they'd ask] |
| ... | ... | ... |
```

**For pre-worked starting tables, see `perspective-library.md`** -- it has
seed perspective/focus/key-question tables for common topic classes (security
review, infra choice, API design, data modeling) plus worked examples for
"Kubernetes service mesh" and "Authentication strategy for API". Use them to
seed the set, then adjust to the specific topic. Perspectives still emerge from
the source survey -- the library is a lookup, not a substitute for discovery.

## Phase 2: Multi-Perspective Research (Parallel)

For each perspective, conduct a simulated conversation between a "writer" and
"topic expert" to generate deep, grounded insights.

### Mode Selection: Subagents vs Agent Team

Choose the research mode based on depth and whether cross-perspective debate
adds value:

| Criterion               | Subagents                | Agent Team                                |
| ----------------------- | ------------------------ | ----------------------------------------- |
| Research depth          | Quick (2-3 perspectives) | Deep (4-5 perspectives, 2-3 turns)        |
| Cross-perspective value | Perspectives orthogonal  | Perspectives should challenge each other  |
| Token budget            | Constrained              | Available                                 |
| Topic type              | Factual, well-bounded    | Contentious, trade-off-heavy              |

**Default to subagents.** Use agent team only when the topic involves genuine
trade-offs between perspectives (e.g., security vs developer experience,
performance vs maintainability).

### Subagent Mode (Default)

Spawn parallel subagents -- one per perspective.
Each reports findings back independently.
The lead synthesizes in Phase 3.

```text
Dispatch subagent (Explore type) per perspective:
  name: "storm-[perspective]"
  prompt: Research "[TOPIC]" from a [ROLE] perspective.

  PROCESS:
  1. Generate 3 initial questions about [TOPIC]
  2. Search for answers using WebSearch and codebase tools
  3. Generate 2 follow-up questions based on findings
  4. Search for those answers
  5. Generate 1 final clarifying question if needed

  OUTPUT FORMAT:
  ## [Role] Perspective
  ### Questions Asked
  1. [Question] -> [Answer with citation]
  ### Key Findings
  - [Finding with source]
  ### Perspective-Specific Concerns
  - [Concern]
  ### Recommendations
  - [Recommendation]
```

### Agent Team Mode (Deep Research with Debate)

When perspectives should challenge each other, create an agent team instead.
Each perspective becomes a teammate with its own context window and the ability
to message other teammates directly.

**Step 1:
Create the team**

```text
Create an agent team to research "[TOPIC]" from multiple expert perspectives.
Spawn [N] teammates:
- [Role 1] focused on [focus area]
- [Role 2] focused on [focus area]
- [Role 3] focused on [focus area]

Each teammate should:
1. Research their perspective (3 initial questions, 2 follow-ups)
2. Publish findings to the task list
3. Read other teammates' findings
4. Challenge or validate other perspectives with evidence
5. Respond to challenges from other teammates

After all perspectives have debated, synthesize findings.
```

**Step 2:
Teammate spawn prompt template**

Each teammate gets a detailed prompt:

```text
You are a [ROLE] researching "[TOPIC]".

PHASE A - Independent Research:
1. Generate 3 questions from your [ROLE] perspective
2. Search for answers with citations
3. Generate 2 follow-up questions, search for answers
4. Summarize your findings

PHASE B - Cross-Perspective Debate:
1. Read other teammates' published findings
2. Identify claims that conflict with your evidence
3. Message the relevant teammate directly with your counter-evidence
4. Respond to challenges from other teammates with citations
5. Update your findings based on debate

OUTPUT: Final perspective summary incorporating debate outcomes.
Mark areas of consensus and unresolved disagreements.
```

**Step 3:
Lead waits for debate to complete**

Tell the lead:
"Wait for all teammates to complete their research and cross-perspective debate
before synthesizing findings."

**Key difference from subagent mode:** Teammates can message each other
directly.
A Security teammate can tell the Developer teammate "your recommendation has an
SSRF vulnerability" without routing through the lead.
This produces higher-quality synthesis because conflicts are resolved through
evidence-based debate rather than post-hoc lead synthesis.

### Conversation Depth

Each perspective should have 2-3 "turns":

```text
Turn 1: Initial questions -> Search -> Answers
Turn 2: Follow-up questions based on Turn 1 -> Search -> Answers
Turn 3: Clarifying questions if gaps remain -> Search -> Answers
```

In agent team mode, add a debate phase after Turn 3 where teammates challenge
each other's findings before finalizing.

This mimics STORM's simulated conversation where the expert's answers inform the
next round of questions.

## Phase 3: Outline Synthesis

After all perspective subagents complete, synthesize their findings into a
unified outline organized by **theme** (not by perspective).

**For outline generation, escalate to the `think` skill** -- explore multiple thematic structures, evaluate, and pick the strongest. Frame the prompt around the research findings:

> I have research findings from 4 perspectives on [TOPIC]. Generate a hierarchical outline organized by THEME:
> - Where do perspectives agree? (high confidence)
> - Where do they conflict? (trade-offs)
> - What unique insights did each reveal?

**Outline structure should be thematic:**

```markdown
## Outline: [TOPIC]

### 1. Core Concepts
- Definition and scope (all perspectives agree)
- Key terminology

### 2. Implementation Approaches
- Option A: [Developer perspective primary]
- Option B: [Platform perspective primary]
- Trade-offs between approaches

### 3. Security Considerations
- Threat model (Security perspective)
- Mitigation strategies
- Compliance requirements

### 4. Operational Concerns
- Deployment (Platform perspective)
- Monitoring and observability
- Scaling considerations

### 5. User Impact
- Experience implications (Product perspective)
- Adoption considerations
```

## Phase 4: Report Generation

Generate the final report by populating the outline with collected information.

**CRITICAL:
Use Basic Memory Only**

Use `write_note` (Basic Memory MCP) to save the report.
The `directory` parameter is a Basic Memory path, not a filesystem path.

**For the full report skeleton and the `write_note` call, see
`report-template.md`** -- copy the template, populate it from the synthesized
outline, and save to `directory="knowledge/research"`.

## Quick vs Deep Research

Adjust the STORM depth based on the request:

### Quick Research (15-20 min)

- 2-3 perspectives
- 1-2 conversation turns per perspective
- Shorter report focused on key findings

### Deep Research (30-45 min)

- 4-5 perspectives
- 2-3 conversation turns per perspective
- Comprehensive report with full analysis

## Best Practices

1. **Perspectives should be genuinely different** - avoid overlapping viewpoints
1. **Each perspective must ground answers in sources** - no speculation
1. **Follow-up questions should dig deeper** - not just rephrase
1. **Outline by theme, not perspective** - synthesize, don't just concatenate
1. **Cite everything** - every claim needs a source
1. **Note conflicts explicitly** - trade-offs are valuable findings
1. **Save incrementally** - perspective summaries can be saved as sub-notes

## Example Invocation

**User:** `/storm Kubernetes service mesh options`

**Agent Process:**

1. **Phase 1:** Discover perspectives (Security Engineer, Platform Engineer,
   Developer, SRE)

1. **Phase 2:** Spawn 4 parallel subagents, each researches from their
   perspective with 2-3 conversation turns

1. **Phase 3:** Synthesize outline (Core concepts, Implementation options,
   Security, Operations, Trade-offs)

1. **Phase 4:** Generate report and save to Basic Memory via
   `write_note(directory="knowledge/research")` (Basic Memory MCP)

## Completion Format

Always end with the STORM completion summary. **See `report-template.md`** for
the copy-paste completion block (saved-location, perspectives, key findings,
trade-offs, recommendation, and follow-up offers).

## References

- [Stanford STORM](https://github.com/stanford-oval/storm) - Original
  implementation
- [STORM Paper (NAACL 2024)](https://aclanthology.org/2024.naacl-long.347/) -
  Academic paper
- [[Research:
  Agentic AI Patterns]] - Pattern evaluation
