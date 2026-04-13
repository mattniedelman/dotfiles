---
name: systematic-debugging
description: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
---

# Systematic Debugging

<!-- QUICK REFERENCE - Follow This -->

## Quick Debugging Checklist

**BEFORE proposing ANY fix, complete these steps:**

1. [ ] **Read error message completely** - Copy exact text
2. [ ] **Identify file and line number** - Go to that location
3. [ ] **Read the code** - Understand what it does
4. [ ] **State hypothesis:** "I believe X causes Y because Z"
5. [ ] **ONLY THEN** propose a single fix

### Loop Prevention

| Failed Attempts | Action                                              |
| --------------- | --------------------------------------------------- |
| 1               | Try your hypothesis                                 |
| 2               | Re-read error, reconsider assumptions               |
| 3+              | STOP. Ask user for help or try different approach   |

### Red Flags - Return to Step 1

If you think any of these, STOP:

- "Let me just try this"
- "This should fix it"
- "One more attempt"

<!-- END QUICK REFERENCE -->

---

## Overview

Random fixes waste time and create new bugs.
Quick patches mask underlying issues.

**Core principle:** ALWAYS find root cause before attempting fixes.
Symptom fixes are failure.

**Follow ALL steps.
No shortcuts.**

## The Mandatory Process

```text
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes.

## When to Use

Use for ANY technical issue:

- Test failures
- Bugs in production
- Unexpected behavior
- Performance problems
- Build failures
- Integration issues

**Use this ESPECIALLY when:**

- Under time pressure (emergencies make guessing tempting)
- "Just one quick fix" seems obvious
- You've already tried multiple fixes
- Previous fix didn't work
- You don't fully understand the issue

## The Four Phases

You MUST complete each phase before proceeding to the next.

### Phase 1: Root Cause Investigation

**BEFORE attempting ANY fix:**

1. **Read Error Messages Carefully**
   - Don't skip past errors or warnings
   - They often contain the exact solution
   - Read stack traces completely
   - Note line numbers, file paths, error codes

2. **Reproduce Consistently**
   - Can you trigger it reliably?
   - What are the exact steps?
   - Does it happen every time?
   - If not reproducible → gather more data, don't guess

3. **Check Recent Changes**
   - What changed that could cause this?
   - Git diff, recent commits
   - New dependencies, config changes
   - Environmental differences

4. **Gather Evidence in Multi-Component Systems**
   - For each component boundary:
     log what enters and exits
   - Run once to gather evidence showing WHERE it breaks
   - THEN analyze evidence to identify failing component

5. **Trace Data Flow**
   - Where does bad value originate?
   - What called this with bad value?
   - Keep tracing up until you find the source
   - Fix at source, not at symptom

### Phase 2: Pattern Analysis

1. **Find Working Examples** - Locate similar working code in same codebase
2. **Compare Against References** - Read reference implementation COMPLETELY
3. **Identify Differences** - List every difference, however small
4. **Understand Dependencies** - What other components does this need?

### Phase 3: Hypothesis and Testing

1. **Form Single Hypothesis** - State clearly:
   "I think X is the root cause because Y"
2. **Test Minimally** - Make the SMALLEST possible change to test hypothesis
3. **Verify Before Continuing** - Did it work?
   Yes → Phase 4.
   No → new hypothesis.
4. **When You Don't Know** - Say so.
   Ask for help.
   Research more.

### Phase 4: Implementation

1. **Create Failing Test Case** - Use test-driven-development skill
2. **Implement Single Fix** - ONE change at a time
3. **Verify Fix** - Test passes now?
   No other tests broken?
4. **If Fix Doesn't Work** - STOP.
   If ≥ 3 fixes failed, question the architecture
5. **If 3+ Fixes Failed** - STOP and question fundamentals.
   Discuss before more fixes.

## Red Flags - STOP and Follow Process

If you catch yourself thinking:

- "Quick fix for now, investigate later"

## Common Rationalizations

| Excuse                                      | Reality                                                                 |
| ------------------------------------------- | ----------------------------------------------------------------------- |
| "Issue is simple, don't need process"       | Simple issues have root causes too. Process is fast for simple bugs.    |
| "Emergency, no time for process"            | Systematic debugging is FASTER than guess-and-check thrashing.          |
| "Just try this first, then investigate"     | First fix sets the pattern. Do it right from the start.                 |
| "I see the problem, let me fix it"          | Seeing symptoms != understanding root cause.                            |
| "One more fix attempt" (after 2+ failures)  | 3+ failures = architectural problem. Question pattern, don't fix again. |

## Quick Reference

| Phase                | Key Activities                                         | Success Criteria            |
| -------------------- | ------------------------------------------------------ | --------------------------- |
| **1.
  Root Cause**    | Read errors, reproduce, check changes, gather evidence | Understand WHAT and WHY     |
| **2.
  Pattern**       | Find working examples, compare                         | Identify differences        |
| **3.
  Hypothesis**    | Form theory, test minimally                            | Confirmed or new hypothesis |
| **4.
  Implementation** | Create test, fix, verify                               | Bug resolved, tests pass    |

## Supporting Techniques

These techniques are part of systematic debugging:

- **`root-cause-tracing.md`** - Trace bugs backward through call stack
- **`defense-in-depth.md`** - Add validation at multiple layers after finding
  root cause
- **`condition-based-waiting.md`** - Replace arbitrary timeouts with condition
  polling

**Related skills:**

- **test-driven-development** - For creating failing test case (Phase 4, Step 1)
- **verification-before-completion** - Verify fix worked before claiming success

## Agent Team Mode: Competing Hypotheses

When the root cause is unclear and multiple plausible theories exist, use an
agent team to investigate hypotheses in parallel.
Teammates actively try to disprove each other's theories, converging on the
actual root cause faster than sequential investigation.

### When to Use Competing Hypotheses

- 3+ plausible hypotheses for the same bug
- Sequential debugging hit Phase 3 twice without confirming a hypothesis
- Bug spans multiple subsystems and no single theory explains all symptoms
- Time-sensitive investigation where parallel exploration justifies token cost

### When NOT to Use

- Single clear hypothesis (standard debugging is faster and cheaper)
- Bug is reproducible and localized to one file/function
- First attempt at debugging (try standard process first)

### The Process

**Step 1:
Form hypotheses (before spawning team)**

Complete Phase 1 (Root Cause Investigation) and Phase 2 (Pattern Analysis)
yourself.
Identify 3-5 distinct hypotheses.
Each must be:

- Falsifiable (there exists evidence that could disprove it)
- Independent (disproving one does not automatically disprove another)
- Specific ("race condition in connection pool" not "timing issue")

**Step 2:
Spawn investigator team**

```text
Create an agent team to debug [SYMPTOM]. Spawn [N] investigators,
each assigned a different hypothesis:

- Investigator 1: [Hypothesis A] - look for evidence in [scope]
- Investigator 2: [Hypothesis B] - look for evidence in [scope]
- Investigator 3: [Hypothesis C] - look for evidence in [scope]

Rules:
1. Each investigator gathers evidence FOR and AGAINST their hypothesis
2. After initial investigation, read other investigators' findings
3. Actively try to disprove other hypotheses with counter-evidence
4. Message other investigators directly when you find contradicting evidence
5. Update your confidence level: CONFIRMED, LIKELY, UNLIKELY, DISPROVED

Do NOT propose fixes until the team reaches consensus on root cause.
```

**Step 3:
Teammate spawn prompt template**

```text
You are debugging [SYMPTOM].

Your hypothesis: [HYPOTHESIS]
Scope: [FILES/SUBSYSTEMS TO INVESTIGATE]

PHASE A - Gather Evidence:
1. Search for evidence supporting your hypothesis
2. Search for evidence contradicting your hypothesis
3. Document both with file paths and line numbers

PHASE B - Cross-Investigation:
1. Read other investigators' findings
2. If their evidence contradicts your hypothesis, acknowledge it
3. If your evidence contradicts their hypothesis, message them directly
4. Respond to challenges with additional evidence or concede

OUTPUT FORMAT:
## Hypothesis: [YOUR HYPOTHESIS]
### Evidence For
- [evidence with file:line citations]
### Evidence Against
- [evidence with file:line citations]
### Confidence: [CONFIRMED/LIKELY/UNLIKELY/DISPROVED]
### Reasoning: [why this confidence level]
```

**Step 4:
Convergence**

Tell the lead:
"Wait for all investigators to complete their cross-investigation phase.
Synthesize into a single root cause determination.
Only then proceed to Phase 4 (Implementation)."

The team should produce one of:

- **Consensus**:
  all investigators agree on root cause
- **Narrowed**:
  eliminated N hypotheses, 1-2 remain for focused investigation
- **Compound**:
  bug has multiple contributing causes (each investigator found a real issue)

### Why This Works

Sequential debugging suffers from anchoring bias:
once you explore one theory, subsequent investigation skews toward confirming
it.
Parallel investigators with adversarial cross-examination break this pattern.
The hypothesis that survives active attempts at disproval is more likely to be
the actual root cause.
