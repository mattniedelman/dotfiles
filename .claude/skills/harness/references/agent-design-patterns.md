# Agent Design Patterns

## Table of Contents

1. [Execution Modes](#execution-modes)
2. [Architecture Patterns](#architecture-patterns)
3. [Composite Patterns](#composite-patterns)
4. [Agent Separation Criteria](#agent-separation-criteria)
5. [Agent Definition Structure](#agent-definition-structure)
6. [Skill vs Agent Distinction](#skill-vs-agent-distinction)

---

## Execution Modes

### Agent Teams -- Default Mode

The lead agent uses `TeamCreate` to form a team.
Members run as independent Claude Code instances, communicate via `SendMessage`,
and self-coordinate via shared task lists (`TaskCreate`/`TaskUpdate`).

```text
[Lead] <-> [Member A] <-> [Member B]
  |            |              |
  +------ Shared Task List ---+
```

**Core tools:**

- `TeamCreate`:
  create team + spawn members
- `SendMessage({to:
  name})`:
  message a specific member
- `SendMessage({to:
  "all"})`:
  broadcast (expensive, use sparingly)
- `TaskCreate`/`TaskUpdate`:
  shared task list management

**Strengths:** direct member-to-member communication, challenge, discovery
sharing, self-coordination via task claims, idle member auto-notification.

**Constraints:** one active team per session (dissolve and reform between
phases), no nested teams, fixed lead, higher token cost.

**Team reconstitution:** when phases need different specialist combinations,
save prior artifacts to `_workspace/`, dissolve with `TeamDelete`, then create
the next team via `TeamCreate`.

### Subagents -- Lightweight Mode

The main agent uses the `Agent` tool to spawn subagents.
Subagents return results to main only -- no inter-subagent communication.

```text
[Main] -> [Sub A] -> result
       -> [Sub B] -> result
       -> [Sub C] -> result
```

**Core tool:** `Agent(prompt, subagent_type, run_in_background)`

**Strengths:** lightweight, fast, token-efficient, result summarized into main
context.

**Constraints:** no inter-subagent communication, main handles all coordination,
no real-time collaboration.

### Mode Selection

```text
2+ agents needed?
+-- Yes -> Inter-agent communication needed?
|          +-- Yes -> Agent Teams (default)
|          +-- No  -> Subagents acceptable
+-- No (1 agent) -> Subagent
```

**Default is Agent Teams.** Choose subagents only when inter-member
communication is genuinely unnecessary.

---

## Architecture Patterns

### 1. Pipeline

Sequential task flow.
Each agent's output feeds the next.

```text
[Analyze] -> [Design] -> [Implement] -> [Verify]
```

**When:** each step depends strongly on the prior step's output.
**Team fit:** limited benefit from Agent Teams unless the pipeline has parallel
sub-steps.
Consider subagents for pure sequential chains.

### 2. Fan-out/Fan-in

Parallel processing followed by result integration.

```text
         +-> [Expert A] -+
[Split] -+-> [Expert B] -+-> [Integrate]
         +-> [Expert C] -+
```

**When:** same input needs analysis from multiple independent perspectives.
**Team fit:** the natural fit for Agent Teams.
Members share discoveries in real-time via `SendMessage`, and one member's
finding can redirect another's investigation.
**Use Agent Teams for this pattern.**

### 3. Expert Pool

Route to the right specialist based on input type.

```text
[Router] -> { Expert A | Expert B | Expert C }
```

**When:** input type determines which processing is needed.
**Team fit:** subagents are more appropriate.
Only the needed expert is invoked; a standing team is wasteful.

### 4. Producer-Reviewer

Generation agent and review agent work in a loop.

```text
[Generate] -> [Review] -> (issues?) -> [Generate] re-run
```

**When:** output quality matters and objective review criteria exist.
**Team fit:** Agent Teams enable real-time feedback via `SendMessage` between
producer and reviewer, reducing rework.
Set max retry count (2-3).

### 5. Supervisor

Central agent manages state and dynamically distributes work.

```text
              +-> [Worker A]
[Supervisor] -+-> [Worker B]
              +-> [Worker C]
```

**When:** workload is variable or distribution happens at runtime.
**Team fit:** Agent Teams' shared task list maps naturally to this pattern.
Workers claim tasks via `TaskCreate`; supervisor monitors via `TaskGet`.

### 6. Hierarchical Delegation

Upper agents recursively delegate to lower agents.

```text
[Lead] -> [Team A Lead] -> [Worker A1, A2]
       -> [Team B Lead] -> [Worker B1]
```

**When:** problem decomposes naturally into a hierarchy.
**Team fit:** Agent Teams cannot nest (members cannot create their own teams).
Use Agent Teams at level 1 and subagents at level 2, or flatten into a single
team.
Keep to 2 levels maximum.

---

## Composite Patterns

| Composite | Components | Example |
| --------- | ---------- | ------- |
| Fan-out + Review | Parallel gen, each reviewed | Translation + review |
| Pipeline + Fan-out | Sequential + parallel | Analyze -> impl -> test |
| Supervisor + Pool | Dynamic routing | Classify then route |

**Default:
use Agent Teams for all composite patterns.** Active member communication is the
core quality driver.

---

## Agent Separation Criteria

| Axis | Separate | Merge |
| ---- | -------- | ----- |
| Specialization | Domains differ | Domains overlap |
| Parallelism | Tasks can run independently | Strictly sequential |
| Context Load | Heavy context per agent | Light, fast tasks |
| Reusability | Useful in other teams | Only relevant here |

---

## Agent Definition Structure

```markdown
---
name: agent-name
description: "1-2 sentence role description. Trigger keywords."
model: inherit  # or opus (deep reasoning) / sonnet (fast code)
---

# Agent Name -- One-Line Role Summary

You are a [domain] [role] specialist.

## Core Role
1. Responsibility one
2. Responsibility two

## Operating Principles
- Principle one (with reasoning)
- Principle two (with reasoning)

## Input/Output Protocol
- Input: [source, format, path]
- Output: [destination, format, path]

## Team Communication Protocol (Agent Teams mode)
- Receive from: [who sends what]
- Send to: [who gets what]
- Task scope: [what task types to claim from shared list]

## Error Handling
- On ambiguous input: [action]
- On failure: [action]
- On timeout: [action]

## Collaboration
- Relationship to other agents in the team
```

---

## Skill vs Agent Distinction

| Aspect | Skill | Agent |
| ------ | ----- | ----- |
| Definition | Procedural knowledge | Specialist persona |
| Location | `.claude/skills/` | `.claude/agents/` |
| Trigger | Keyword matching | Explicit invocation |
| Size | Small to large (workflow) | Small (role definition) |
| Purpose | "How to do it" | "Who does it" |

Skills are procedural guides that agents reference during execution.
Agents are specialist roles that use skills.
