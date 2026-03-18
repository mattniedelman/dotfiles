---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load plan, review critically, execute tasks in batches, report for review
between batches.

**Core principle:** Batch execution with checkpoints for architect review.

**Announce at start:** "I'm using the executing-plans skill to implement this
plan."

## The Process

### Step 1: Load and Review Plan

1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns:
   Raise them with your human partner before starting
4. If no concerns:
   Create task list and proceed

### Step 2: Execute Batch

**Default:
First 3 tasks**

For each task:

1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

### Step 3: Report

When batch complete:

- Show what was implemented
- Show verification output
- Say:
  "Ready for feedback."

### Step 4: Continue

Based on feedback:

- Apply changes if needed
- Execute next batch
- Repeat until complete

### Step 5: Complete Development

After all tasks complete and verified:

- Announce:
  "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**

- Hit a blocker mid-batch (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**

- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember

- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Between batches:
  just report and wait
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**

- **superpowers:using-git-worktrees** - REQUIRED:
  Set up isolated workspace before starting
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:finishing-a-development-branch** - Complete development after
  all tasks

## Workflow Integration

**Phase:** EXECUTE

**Inputs:**
- Implementation plan from `artifacts/plans/{feature}` in Basic Memory

**Outputs:**
- Code changes (tracked by version control)
- Updated plan with completed tasks

**Pre-check:**
Before executing, verify plan exists:
- Check Basic Memory for plan artifact
- If none found: "No plan found. Run PLAN phase with `writing-plans` first?"
- Review plan critically before starting

**Handoff:**
When execution is complete:
1. Ensure all changes are staged/committed
2. Declare: "**Phase Complete: EXECUTE -> VERIFY**"
3. Suggest: "Ready for `verification-before-completion`"

**Related Skills:**
- `writing-plans` - Previous phase (PLAN)
- `test-driven-development` - Use within EXECUTE for each task
- `subagent-driven-development` - Alternative for parallel execution
- `verification-before-completion` - Next phase (VERIFY)
