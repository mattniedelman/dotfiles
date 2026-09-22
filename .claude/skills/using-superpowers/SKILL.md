---
name: using-superpowers
description: Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions
---

<!-- QUICK REFERENCE - Follow This -->

## Skill Decision (Every Response)

1. Read user message
2. Scan skill list - ANY might apply?
3. IF found → Read skill → Follow exactly
4. IF not found → Proceed

**No exceptions.
No rationalizations.**

### Common Skill Triggers

| User Says | Use Skill |
|-----------|-----------|
| "Fix this bug" | systematic-debugging |
| "Add feature X" | brainstorm → design-plans |
| "Is this done?" | verification-before-completion |
| "Write tests" | test-driven-development |
| "Continue from yesterday" | continue-conversation |
| "Review this" | requesting-code-review |

### Phase Declaration

Before significant work, state:

```text
**Phase: EXPLORE** | **Phase: PLAN** | **Phase: EXECUTE** | **Phase: VERIFY** | **Phase: LEARN**
```

<!-- END QUICK REFERENCE -->

---

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE.
YOU MUST USE IT.

This is not negotiable.
This is not optional.
You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## How to Access Skills

Skills are markdown files in `~/.claude/skills/<name>/SKILL.md`.
Claude Code loads them based on the `description` field in the YAML frontmatter.

# Using Skills

## The Rule

**Invoke relevant or requested skills BEFORE any response or action.** Even a 1%
chance a skill might apply means that you should invoke the skill to check.
If an invoked skill turns out to be wrong for the situation, you don't need to
use it.

```dot
digraph skill_flow {
    "User message received" [shape=doublecircle];
    "Might any skill apply?" [shape=diamond];
    "Read skill content" [shape=box];
    "Announce: 'Using [skill] to [purpose]'" [shape=box];
    "Has checklist?" [shape=diamond];
    "Create task list per item" [shape=box];
    "Follow skill exactly" [shape=box];
    "Respond (including clarifications)" [shape=doublecircle];

    "User message received" -> "Might any skill apply?";
    "Might any skill apply?" -> "Read skill content" [label="yes, even 1%"];
    "Might any skill apply?" -> "Respond (including clarifications)" [label="definitely not"];
    "Read skill content" -> "Announce: 'Using [skill] to [purpose]'";
    "Announce: 'Using [skill] to [purpose]'" -> "Has checklist?";
    "Has checklist?" -> "Create task list per item" [label="yes"];
    "Has checklist?" -> "Follow skill exactly" [label="no"];
    "Create task list per item" -> "Follow skill exactly";
}
```

## Red Flags

These thoughts mean STOP -- you're rationalizing:

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for skills. |
| "Let me gather information first" | Skills tell you HOW to gather information. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "This doesn't count as a task" | Action = task. Check for skills. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
| "I know what that means" | Knowing the concept ≠ using the skill. Invoke it. |

## Skill Priority

When multiple skills could apply, use this order:

1. **Process skills first** (brainstorming, debugging) - these determine HOW to
   approach the task
2. **Implementation skills second** (frontend-design, mcp-builder) - these guide
   execution

"Let's build X" → brainstorming first, then implementation skills.
"Fix this bug" → debugging first, then domain-specific skills.

## Skill Types

**Rigid** (TDD, debugging):
Follow exactly.
Don't adapt away discipline.

**Flexible** (patterns):
Adapt principles to context.

The skill itself tells you which.

## User Instructions

Instructions say WHAT, not HOW.
"Add X" or "Fix Y" doesn't mean skip workflows.

## Phase Awareness

Significant work flows through five phases -- EXPLORE, PLAN, EXECUTE, VERIFY,
LEARN -- and you should declare your current phase before acting.

**See `phases.md`** for the full model: the Five Phases table, phase-transition
triggers, anti-patterns, common skill chains, the artifact-connection diagram,
the handoff protocol, and pre-checks. Consult it when planning multi-phase
work.
