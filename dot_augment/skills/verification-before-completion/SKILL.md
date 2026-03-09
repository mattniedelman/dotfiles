---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

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

## The Bottom Line

**No shortcuts for verification.**

Run the command.
Read the output.
THEN claim the result.

This is non-negotiable.
