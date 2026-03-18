---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

<!-- QUICK REFERENCE - Follow This -->

## Quick Verification (Always Do This)

1. **Run test command** → See output
2. **Confirm:** "X/X passed" or "0 failures"
3. **Run lint command** → See output
4. **Confirm:** "0 errors"
5. **ONLY THEN** claim success

### Checklist Before Saying "Done"

- [ ] Tests pass (saw output)
- [ ] Lint passes (saw output)
- [ ] Build succeeds (saw exit 0)
- [ ] All requirements addressed

### Prohibited Claims Without Evidence

| Say This | Not This |
|----------|----------|
| "pytest: 34/34 passed" | "should work now" |
| "ruff: 0 errors" | "looks correct" |
| "exit code 0" | "I believe it's fixed" |

<!-- END QUICK REFERENCE -->

---

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```text
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it
passes.

## Goal-Backward Verification

**Task completion ≠ Goal achievement.**

A task "create chat component" can be marked complete when the component is a
placeholder.
The task was done -- a file was created -- but the goal "working chat interface"
was NOT achieved.

### The Three Levels

Before claiming completion, verify at ALL three levels:

| Level | Question | Failure Mode |
|-------|----------|--------------|
| **1.
  Exists** | Does the artifact exist? | File missing |
| **2.
  Substantive** | Is it real code, not a stub? | Placeholder/TODO |
| **3.
  Wired** | Is it connected to the system? | Orphaned code |

## Evaluation Tiers

Verification operates at multiple tiers.
Lower tiers are prerequisites for higher tiers.

### Tier 1: Functional (Does it work?)

| Check | Method |
|-------|--------|
| Code compiles/parses | Build command exits 0 |
| Tests pass | Test command shows 0 failures |
| No runtime errors | App starts without crashing |
| Feature behaves correctly | Manual or automated verification |

### Tier 2: Completeness (Is it done?)

| Check | Method |
|-------|--------|
| All requirements addressed | Line-by-line checklist against spec |
| Edge cases handled | Tests exist for boundary conditions |
| Error states handled | Invalid input produces useful errors |
| All three levels verified | Exists + Substantive + Wired |

### Tier 3: Quality (Is it good?)

| Check | Method |
|-------|--------|
| Lint clean | Linter output shows 0 errors |
| Type safe | Type checker passes |
| No code smells | ast-grep rules pass |
| Follows project patterns | Matches existing conventions |
| Readable and maintainable | Self-review against style guide |

### Tier 4: Learning (What did we learn?)

| Check | Method |
|-------|--------|
| Decisions documented | Basic Memory notes updated |
| Patterns captured | Reusable insights recorded |
| Gotchas noted | Future-self warnings added |
| Related work identified | Links to affected areas documented |

### Tier Application

| Claim | Minimum Tier Required |
|-------|----------------------|
| "It compiles" | Tier 1 |
| "Tests pass" | Tier 1 |
| "Feature complete" | Tier 2 |
| "Ready for review" | Tier 3 |
| "Work complete" | Tier 4 |

### Quick Tier Checklist

```text
Before claiming DONE:
[ ] Tier 1: Build passes, tests pass, no runtime errors
[ ] Tier 2: All requirements met, edge cases covered, 3 levels verified
[ ] Tier 3: Lint clean, types pass, follows patterns
[ ] Tier 4: Decisions captured, patterns documented, learnings recorded
```

### Observable Truths

Before claiming a GOAL is achieved, state what must be TRUE:

```text
Goal: "Working user authentication"

Truths that must hold:
- User can register with email/password
- User can log in with valid credentials
- Invalid credentials are rejected with error
- Authenticated user can access protected routes
- Unauthenticated user is redirected to login
```

Each truth is verifiable by a human using the application.

### Stub Detection Patterns

**Red flags that indicate Level 2 failure (stub, not real):**

```python
# Component stubs
return <div>Placeholder</div>
return None
return {}
return []

# Handler stubs
onClick={() => {}}
onChange={() => console.log('clicked')}
onSubmit={(e) => e.preventDefault()}  # Only prevents default

# API stubs
return Response.json({ message: "Not implemented" })
return Response.json([])  # Empty array with no DB query

# TODO/FIXME markers
# TODO: implement this
# FIXME: add real logic
# PLACEHOLDER
```

### Wiring Verification (Level 3)

**Red flags that indicate Level 3 failure (exists but not wired):**

```python
# Fetch exists but response ignored
fetch('/api/messages')  # No await, no .then, no assignment

# Query exists but result not returned
await prisma.message.findMany()
return Response.json({ ok: True })  # Returns static, not query result

# State exists but not rendered
const [messages, setMessages] = useState([])
return <div>No messages</div>  # Always shows "no messages"

# Component exists but not imported/used anywhere
# grep shows 0 imports of the new component
```

### Key Link Verification

Identify critical connections where breakage causes cascading failures:

| Link Type | How to Verify |
|-----------|---------------|
| Component → API | grep for fetch/axios call to the endpoint |
| API → Database | grep for prisma/db query returning to response |
| Form → Handler | grep for onSubmit with actual API call |
| State → Render | grep for state variable in JSX |

## The Gate Function

```text
BEFORE claiming any status or expressing satisfaction:

1. STATE THE GOAL: What outcome was promised? (not what tasks were done)
2. DERIVE TRUTHS: What must be TRUE for the goal to be achieved?
3. CHECK LEVELS: For each truth:
   a. Level 1: Does the artifact exist?
   b. Level 2: Is it substantive (not a stub)?
   c. Level 3: Is it wired (connected to the system)?
4. RUN VERIFICATION: Execute commands that prove the truths
5. READ OUTPUT: Full output, check exit code, examine results
6. VERIFY: Does output confirm ALL truths?
   - If NO: State actual status with evidence, identify gaps
   - If YES: State claim WITH evidence
7. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |
| Feature works | All 3 levels verified | File exists |
| Goal achieved | Observable truths verified | Tasks completed |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!",
  etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**
- Claiming "feature complete" when only Level 1 (exists) was verified
- Skipping Level 3 (wiring) because "the code is there"
- Confusing "task done" with "goal achieved"

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |

## Key Patterns

**Tests:**

```text
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**

```text
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**

```text
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**

```text
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**

```text
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

**Goal-backward (feature completion):**

```text
✅ State goal → Derive truths → Check Level 1/2/3 for each → Run verification
   Example:
   Goal: "User authentication"
   Truth: "User can log in"
   Level 1: src/api/auth/login/route.ts exists? YES
   Level 2: Contains actual auth logic (not placeholder)? grep shows bcrypt, JWT
   Level 3: Wired to UI? grep shows LoginForm imports and calls /api/auth/login
   Verification: curl -X POST /api/auth/login returns 200 with valid creds

❌ "I created the auth files" (Level 1 only)
❌ "The component exists" (no Level 2/3 check)
❌ "Tests pass" (tests may not cover wiring)
```

## When To Apply

**ALWAYS before:**

- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

## Fix-Revalidate Loop (MANDATORY)

When verification fails and you fix an issue, you MUST re-run the FULL
verification suite, not just the specific failing check.

```text
┌─────────────────────────────────────────────────────────────┐
│ FIX-REVALIDATE LOOP                                         │
│                                                             │
│ 1. Run FULL verification suite                              │
│ 2. IF failure → Fix the specific issue                      │
│ 3. Run FULL verification suite AGAIN (not just that test)   │
│ 4. IF new failure → Go to step 2                            │
│ 5. IF all pass → Proceed                                    │
│                                                             │
│ ⚠️  NEVER assume "fixing X can't break Y"                   │
│ ⚠️  NEVER run only the previously-failing test              │
│ ⚠️  NEVER skip re-running because "it's unrelated"          │
└─────────────────────────────────────────────────────────────┘
```

**Why full re-verification?**

| Assumption | Reality |
|------------|---------|
| "This fix only affects X" | Fixes often have side effects |
| "Y was passing before" | Your fix may have broken Y |
| "It's just a typo fix" | Typo fixes can change behavior |
| "I only changed one line" | One line can cascade |

**Counter-example (WRONG):**

```text
1. Run tests → 3 fail
2. Fix test A → Run test A → Passes
3. Fix test B → Run test B → Passes
4. Fix test C → Run test C → Passes
5. Claim "all tests pass" ← WRONG: Never ran full suite after fixes
```

**Correct approach:**

```text
1. Run ALL tests → 3 fail
2. Fix test A
3. Run ALL tests → 2 fail, test A passes
4. Fix test B
5. Run ALL tests → 1 fail, tests A & B pass
6. Fix test C
7. Run ALL tests → 0 fail
8. Claim "all tests pass" ← CORRECT: Full suite verified
```

## The Bottom Line

**No shortcuts for verification.**

Run the command.
Read the output.
THEN claim the result.

This is non-negotiable.

## Workflow Integration

**Phase:** VERIFY

**Inputs:**

- Completed code changes from EXECUTE phase
- Spec from `artifacts/specs/{feature}` (for requirements check)
- Plan from `artifacts/plans/{feature}` (for completeness check)

**Outputs:**

- Verification report (inline, not persisted)
- Updated task states

**Pre-check:** Before verifying:

- Are there changes to verify?
  Check version control status.
- Was EXECUTE phase completed?
  Check plan task states.

**Handoff:** When verification passes:

1. Summarize verification results
2. Declare:
   "**Phase Complete:
   VERIFY -> LEARN**"
3. Suggest:
   "Ready for `knowledge-capture` to document insights"

When verification fails:

1. Identify specific failures
2. Declare:
   "**Returning to EXECUTE phase**"
3. Fix issues, then re-verify

**Related Skills:**

- `executing-plans` - Previous phase (EXECUTE)
- `test-driven-development` - For writing regression tests
- `knowledge-capture` - Next phase (LEARN)
