---
name: writing-skills
description: Use when creating new skills, editing existing skills, or verifying skills work before deployment
---

# Writing Skills

## Overview

**Writing skills IS Test-Driven Development applied to process documentation.**

You write test cases (pressure scenarios with subagents), watch them fail
(baseline behavior), write the skill (documentation), watch tests pass (agents
comply), and refactor (close loopholes).

**Core principle:** If you didn't watch an agent fail without the skill, you
don't know if the skill teaches the right thing.

**REQUIRED BACKGROUND:** You MUST understand test-driven-development before
using this skill.

## What is a Skill?

A **skill** is a lazily-loaded SKILL.md document with YAML frontmatter that
Claude can invoke automatically (description-matching) or on user command
(`/skill-name`).
The description is pre-loaded at session start so Claude knows what skills
exist; the full body loads only when invoked.

**Skills are:** Reusable techniques, patterns, reference guides, standing
instructions for how Claude should behave in a recurring situation.

**Skills are NOT:** Narratives about how you solved a problem once.
Hooks (event-driven automation).
Agents (spawned workers with isolated context).

## Skills vs. Hooks vs. Agents

| Mechanism | Configured in | Triggered by | Use for |
|-----------|--------------|-------------|---------|
| **Skill** | `skills/<name>/SKILL.md` | Description match or `/name` | Recurring process guidance, on-demand reference |
| **Hook** | `settings.json` hooks array | Lifecycle events (SessionStart, PreToolUse, etc.) | Unconditional automation around specific events |
| **Agent** | AGENT.md or Agent tool | Explicit invocation | Isolated subagent work with its own context window |

Hooks and skills are not interchangeable.
A hook fires regardless of Claude's choices; a skill fires when Claude
recognizes it's appropriate or the user invokes it.
Use a hook when the behavior must happen at a lifecycle point unconditionally;
use a skill when the guidance should apply on-demand.

## When to Create a Skill

**Create when:**

- Technique wasn't intuitively obvious to you
- You'd reference this again across projects
- Pattern applies broadly (not project-specific)
- Others would benefit

**Don't create for:**

- One-off solutions
- Standard practices well-documented elsewhere
- Project-specific conventions
- Mechanical constraints (automate with a hook instead)

## Skill Types

### By Content

| Type | Purpose | Example |
|------|---------|---------|
| **Technique** | Concrete method with steps | condition-based-waiting, root-cause-tracing |
| **Pattern** | Way of thinking about problems | flatten-with-flags, test-invariants |
| **Reference** | API docs, syntax guides | helm-kubernetes, fastapi |

### By Rigidity

| Type | Characteristics | Examples |
|------|-----------------|----------|
| **Rigid** | Iron Law, no exceptions, explicit loophole closing | TDD, verification-before-completion |
| **Flexible** | Principles that adapt to context, "prefer" language | brainstorming, api-design |

The skill itself should declare which type it is.
Rigid skills require complete adherence.

## Directory Structure

```text
skills/
  skill-name/
    SKILL.md              # Main reference (required)
    supporting-file.*     # Only if needed
```

## SKILL.md Frontmatter

All supported fields:

| Field | Required | Purpose |
|-------|----------|---------|
| `name` | yes | Lowercase letters, numbers, hyphens only (1-64 chars) |
| `description` | yes* | When to invoke. First sentence is highest-leverage -- put key use case there |
| `when_to_use` | no | Extended trigger conditions, appended to `description` for matching |
| `disable-model-invocation` | no | Set `true` for skills with side effects or timing requirements |
| `context` | no | Set `fork` to run skill in an isolated subagent |
| `skills` | no | List of skills to preload into a forked subagent's context |
| `hooks` | no | Hooks scoped to this skill's lifecycle only |

*If omitted, Claude falls back to the first paragraph of the body.

### Description field rules

The `description` field is the skill's **entire public API at session start**.
It is the only thing Claude sees until the skill is invoked -- treat it as an
interface, not a summary. Claude uses it to decide when to invoke; if it is
wrong or vague, the skill either fires when it shouldn't or stays silent when
it should fire.

The combined `description` + `when_to_use` text is **truncated at 1,536
characters**. When the context budget overflows, descriptions for least-used
skills are dropped first.

- Start with "Use when..."
- Put the key use case in the first sentence
- Describe WHEN to use, never WHAT the skill does
- Never summarize the skill's process or workflow
- Use `when_to_use` to add trigger detail without bloating `description`

### Description Examples

| Quality | Example | Why |
|---------|---------|-----|
| Good | "Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes" | Specifies trigger conditions |
| Good | "Use when about to claim work is complete, fixed, or passing, before committing" | Describes WHEN, not WHAT |
| Bad | "A systematic four-phase debugging process with root cause analysis" | Describes the process, not when to use |
| Bad | "Helps with testing and quality assurance" | Vague, no trigger conditions |

### disable-model-invocation

Set `disable-model-invocation: true` for any skill with side effects or timing
requirements. This removes the skill from Claude's context entirely -- Claude
has no knowledge of it until you invoke it manually.

Use for `/deploy`, `/commit`, `/send-slack-message`, or any skill where
accidental auto-triggering would cause real consequences.

Without this flag, Claude can and will auto-invoke a skill whenever its
description matches the current context.

### context: fork

Set `context: fork` when the skill should run in an isolated subagent. The
skill content becomes the subagent's driving prompt; it starts with a fresh
context window and has no access to the parent conversation history.

Use when the skill does heavy work that would pollute the parent context window,
or when the guidance is self-contained and doesn't need prior conversation.

## Skill Lifecycle

Once invoked, the rendered SKILL.md content enters the conversation as a single
message and **persists for the rest of the session**.
Claude Code does not re-read the skill file on later turns.

**Consequence for authors:** Write guidance as standing instructions, not
one-time steps.
If a rule should apply throughout a task, phrase it as a persistent constraint,
not a procedure to execute once.

Caveat:
Auto-compaction can drop older skills.
After compaction, only the most recent invocation of each skill is re-attached,
up to 5,000 tokens per skill within a 25,000-token shared budget.

### Progressive Disclosure

Skills load in three layers. Each layer is only as large as its job requires.

| Layer | When loaded | Size target | What belongs here |
|-------|------------|------------|-------------------|
| **Description** | Session start | <1,536 chars | Trigger conditions only -- the "when", never the "what" |
| **Body** | On invocation | <5,000 tokens | Standing instructions, principles, decision tables |
| **Resources** | On demand (file refs) | Unlimited | Reference tables, API docs, extended examples, lookup content |

**Description (`description` + `when_to_use`)** -- pre-loaded for every skill
at session start. Keep it tight: trigger conditions and key use cases only.
`when_to_use` is the overflow valve -- add nuanced trigger scenarios there
without crowding the primary `description`.

**Body** -- loaded once when the skill is invoked and persists for the session.
Write standing instructions here: rules, decision criteria, checklists. Avoid
reference material the agent only needs occasionally -- that inflates activation
cost for every invocation.

**Resources** -- separate files in the skill directory, referenced from the
body as needed. Move content here when it is only consulted sometimes:

- Long lookup tables
- Extended examples or templates
- API reference sections
- Anything that would push the body past 5,000 tokens

```text
skills/
  my-skill/
    SKILL.md         # description + standing instructions (<5k tokens)
    reference.md     # lookup tables, extended examples
    template.md      # fill-in-the-blank artifacts
```

**Design heuristic:** if a reader could skip a section on 80% of invocations,
it belongs in a resource file, not the body.

**Stock the resource layer additively -- do not just spill into it.** The 80%
heuristic decides what to _relocate_ out of the body, but it does not tell you
what the resource layer should _contain_. Resources are loaded only on demand,
so the cold layer is effectively free shelf space -- and free space left empty
is wasted, not virtuous. After draining the body, ask the additive question:
**what would an expert keep open in another tab while doing this task?**

- Complete worked examples and copy-paste-ready artifacts (a full config, a
  hardened reference implementation, a filled-in template)
- Decision tables, recipe snippets, and capability/version-gating patterns
- The detailed mechanics behind a rule the body only summarizes

Much of this was never a body candidate -- it would never have "overflowed" --
so a purely subtractive author never creates it. A resource file that only
restates the body in more words is **under-stocked**: it pays the cost of a
second file without delivering the copy-worthy material that justifies one.
Point to canonical sources rather than reproducing standard API docs, but the
skill's own judgment -- worked examples, gotcha-avoidance baked into real
artifacts -- belongs in the cold layer in full.

## The Iron Law (Same as TDD)

```text
NO SKILL WITHOUT A FAILING TEST FIRST
```

This applies to NEW skills AND EDITS to existing skills.

Write skill before testing?
Delete it.
Start over.

## RED-GREEN-REFACTOR for Skills

### RED: Write Failing Test (Baseline)

Run pressure scenario with subagent WITHOUT the skill.
Document exact behavior:

- What choices did they make?
- What rationalizations did they use (verbatim)?
- Which pressures triggered violations?

### GREEN: Write Minimal Skill

Write skill that addresses those specific rationalizations.
Don't add extra content for hypothetical cases.

Run same scenarios WITH skill.
Agent should now comply.

### REFACTOR: Close Loopholes

Agent found new rationalization?
Add explicit counter.
Re-test until bulletproof.

## Bulletproofing Skills Against Rationalization

### Close Every Loophole Explicitly

Don't just state the rule - forbid specific workarounds:

```text
Bad:  "Write tests first"
Good: "Write test first. Write code before test? Delete it. Start over.
      Don't keep as reference. Don't adapt. Delete means delete."
```

### Address "Spirit vs Letter" Arguments

Add foundational principle early in rigid skills:

```text
**Violating the letter of the rules is violating the spirit of the rules.**
```

### Build Rationalization Table

Capture rationalizations from baseline testing.
Every excuse agents make goes in the table:

| Excuse | Reality |
|--------|---------|
| "Too simple for this process" | Simple tasks have requirements too. Process is fast for simple cases. |
| "I'll do it properly next time" | First attempt sets the pattern. Do it right from the start. |
| "Emergency, no time" | Systematic process is FASTER than ad-hoc thrashing. |
| "I'm confident this works" | Confidence is not evidence. Run verification. |
| "Just this once" | No exceptions. "Just this once" is how all failures start. |

### Create Red Flags List

Make it easy for agents to self-check when rationalizing:

**If you're thinking any of these, STOP:**

- "This is just a simple case"
- "I'll come back and do it properly"
- "The skill is overkill for this"
- "I know what I'm doing"
- "Let me just try this first"
- Using "should", "probably", "seems to" about outcomes

## Skill Creation Checklist

**RED Phase:**

- [ ] Create pressure scenarios
- [ ] Run scenarios WITHOUT skill - document baseline
- [ ] Identify patterns in rationalizations

**GREEN Phase:**

- [ ] Name uses only letters, numbers, hyphens
- [ ] YAML frontmatter with required fields
- [ ] Description starts with "Use when..."
- [ ] Key use case in first sentence of description
- [ ] `disable-model-invocation: true` if any side effects
- [ ] Address specific baseline failures
- [ ] One excellent example
- [ ] Resource layer stocked additively -- copy-worthy artifacts (worked
      examples, recipes, detailed mechanics), not body prose restated
- [ ] Run scenarios WITH skill - verify compliance

**REFACTOR Phase:**

- [ ] Identify NEW rationalizations
- [ ] Add explicit counters
- [ ] Build rationalization table
- [ ] Create red flags list
- [ ] Re-test until bulletproof

**Deployment:**

- [ ] Commit skill to git
- [ ] Consider contributing back via PR

## Security Considerations

- Never hardcode sensitive information in skills
- Review any downloaded skills before enabling
- Use MCP connections for external service access
- Exercise caution with executable scripts

## Verification Gate

Before claiming a skill is complete:

```text
1. BASELINE: Did you watch agents fail WITHOUT the skill?
2. COMPLIANCE: Did you verify agents comply WITH the skill?
3. LOOPHOLES: Did you counter observed rationalizations?
4. DESCRIPTION: Does it start with "Use when..." and put key use case first?
5. SIDE EFFECTS: If the skill has side effects, is disable-model-invocation set?
6. TESTED: Did you run pressure scenarios?

All six = ready to deploy.
Missing any = not done.
```

## The Bottom Line

**Creating skills IS TDD for process documentation.**

Same Iron Law:
No skill without failing test first.

Same cycle:
RED (baseline) -> GREEN (write skill) -> REFACTOR (close loopholes).

**Violating the letter of this skill is violating the spirit of skill
creation.**
