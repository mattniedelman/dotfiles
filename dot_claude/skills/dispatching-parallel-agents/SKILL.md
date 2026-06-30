---
name: dispatching-parallel-agents
description: Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies
---

# Dispatching Parallel Agents

## Overview

When you have multiple unrelated failures (different test files, different
subsystems, different bugs), investigating them sequentially wastes time.
Each investigation is independent and can happen in parallel.

**Core principle:** Dispatch one agent per independent problem domain.
Let them work concurrently.

## When to Use

```dot
digraph when_to_use {
    "Multiple failures?" [shape=diamond];
    "Are they independent?" [shape=diamond];
    "Single agent investigates all" [shape=box];
    "One agent per problem domain" [shape=box];
    "Can they work in parallel?" [shape=diamond];
    "Sequential agents" [shape=box];
    "Parallel dispatch" [shape=box];

    "Multiple failures?" -> "Are they independent?" [label="yes"];
    "Are they independent?" -> "Single agent investigates all" [label="no - related"];
    "Are they independent?" -> "Can they work in parallel?" [label="yes"];
    "Can they work in parallel?" -> "Parallel dispatch" [label="yes"];
    "Can they work in parallel?" -> "Sequential agents" [label="no - shared state"];
}
```

**Use when:**

- 3+ test files failing with different root causes
- Multiple subsystems broken independently
- Each problem can be understood without context from others
- No shared state between investigations

**Don't use when:**

- Failures are related -- fixing one might fix others; investigate together first
- You need to understand full system state to make sense of the problem
- Exploratory debugging -- you don't know what's broken yet
- Shared state -- agents would interfere (editing same files, using same resources)

## The Pattern

### 1. Identify Independent Domains

Group failures by what's broken:

- File A tests:
  Tool approval flow
- File B tests:
  Batch completion behavior
- File C tests:
  Abort functionality

Each domain is independent - fixing tool approval doesn't affect abort tests.

### 2. Create Focused Agent Tasks

Each agent gets:

- **Specific scope:** One test file or subsystem
- **Clear goal:** Make these tests pass
- **Constraints:** Don't change other code
- **Expected output:** Summary of what you found and fixed

### 3. Dispatch in Parallel

Use sub-agents with clear, focused instructions for each domain. See
[example-dispatch.md](example-dispatch.md) for copy-paste `Agent()` prompts.

### 4. Review and Integrate

When agents return:

- Read each summary
- Verify fixes don't conflict
- Run full test suite
- Integrate all changes

## Agent Prompt Structure

Good agent prompts are:

1. **Focused** - One clear problem domain
2. **Self-contained** - All context needed to understand the problem
3. **Specific about output** - What should the agent return?

## Common Mistakes

**❌ Too broad:** "Fix all the tests" - agent gets lost **✅ Specific:** "Fix
agent-tool-abort.test.ts" - focused scope

**❌ No context:** "Fix the race condition" - agent doesn't know where **✅
Context:** Paste the error messages and test names

**❌ No constraints:** Agent might refactor everything **✅ Constraints:** "Do NOT
change production code" or "Fix tests only"

**❌ Vague output:** "Fix it" - you don't know what changed **✅ Specific:**
"Return summary of root cause and changes"

For copy-paste `Agent()` dispatch prompts (scope + goal + constraints +
expected-output filled in) and a worked multi-failure parallel dispatch, see
[example-dispatch.md](example-dispatch.md).

## Verification

After agents return:

1. **Review each summary** - Understand what changed
2. **Check for conflicts** - Did agents edit same code?
3. **Run full suite** - Verify all fixes work together
4. **Spot check** - Agents can make systematic errors
