---
description: Generate a comprehensive monthly review report with highlights, metrics, and quarterly goal tracking
argument-hint: [month] [year]
allowed-tools: mcp__basic-memory__write_note, mcp__basic-memory__search_notes, mcp__basic-memory__read_note, mcp__basic-memory__build_context, mcp__basic-memory__recent_activity, github-api
---

# Monthly Review

Generate a comprehensive monthly review report with highlights, lowlights, strategic priorities, metrics, and quarterly goal tracking.

## Prerequisites

First, read and follow the skill at: `~/.augment/skills/monthly-review/SKILL.md`

## Arguments

- `$1` - Month number (1-12, optional, default: current/previous month)
- `$2` - Year (optional, default: current year)

## Your Task

Generate a monthly review for: **$ARGUMENTS** (or current month if not specified)

### 1. Determine Review Period

Parse arguments to determine the month and year:
- If no args: Use previous month if we're in first week, else current month
- If one arg (1-12): That month of current year
- If two args: Month and year specified

Calculate date range:
- Start: First day of target month
- End: Last day of target month

### 2. Check for Quarterly Goals

Search for existing quarterly goals documentation:

```python
search_notes_basic-memory(query="quarterly goals Q1 Q2 Q3 Q4 OKR objectives")
search_notes_basic-memory(query="strategic goals priorities")
```

**If quarterly goals NOT found:**
- Inform user: "No quarterly goals found in Basic Memory."
- Ask: "Would you like to provide your quarterly goals now, or point me to where they're documented?"
- Offer to create a quarterly goals template

**If found:**
- Read the goals document
- Map them for the tracking table

### 3. Gather Monthly Activity

#### From Basic Memory

```python
# Get all recent activity
recent_activity_basic-memory(timeframe="30 days")

# Search for accomplishments
search_notes_basic-memory(
    query="completed finished shipped launched implemented",
    after_date="<YYYY-MM-01>"
)

# Search for decisions
search_notes_basic-memory(
    query="decision decided chose selected",
    after_date="<YYYY-MM-01>"
)

# Search for challenges
search_notes_basic-memory(
    query="blocked issue problem challenge failed",
    after_date="<YYYY-MM-01>"
)

# Search for metrics
search_notes_basic-memory(
    query="metrics performance numbers",
    after_date="<YYYY-MM-01>"
)
```

#### From GitHub PRs

Query GitHub to understand actual code progress:

```python
# Get merged PRs by user in the review period
github-api(
    path="/search/issues",
    data={
        "q": "is:pr is:merged author:@me merged:YYYY-MM-01..YYYY-MM-31",
        "per_page": 50
    },
    summary="Get merged PRs for month"
)

# Get open PRs (work in progress)
github-api(
    path="/search/issues",
    data={
        "q": "is:pr is:open author:@me",
        "per_page": 20
    },
    summary="Get open PRs"
)

# Get PRs reviewed by user (collaboration metric)
github-api(
    path="/search/issues",
    data={
        "q": "is:pr reviewed-by:@me -author:@me merged:YYYY-MM-01..YYYY-MM-31",
        "per_page": 30
    },
    summary="Get PRs reviewed"
)
```

**Extract from PRs:**
- **Merged PR count**: Completed work
- **Merged PR titles**: What was accomplished
- **Open PR count**: Work in progress
- **PRs reviewed**: Collaboration/mentorship
- **Blocked PRs**: PRs with failing CI or stale reviews

### 4. Build Context

For key findings, build deeper context:

```python
build_context_basic-memory(
    url="memory://relevant-topic",
    timeframe="30 days",
    depth=1
)
```

### 5. Analyze and Categorize

Review all gathered data:

**Highlights:**
- Completed projects/features
- Decisions made
- Wins and achievements
- Progress on goals

**Lowlights:**
- Blockers encountered
- Missed deadlines
- Challenges faced
- Goals not met

**Metrics:**
- Any quantitative data
- Comparisons to previous periods
- Trend indicators

**Goal Progress:**
- Map activities to quarterly goals
- Assess health status (🔴/🟡/🟢)
- Identify next steps

### 6. Draft Report

Create the report following the template in the skill. Include all sections:
1. Executive summary
2. Highlights
3. Lowlights  
4. Strategic priorities
5. Key metrics
6. Quarterly goals table

### 7. Present Draft for Review

Before saving, present the draft to the user:

```
## 📋 Monthly Review Draft: <Month> <Year>

[Full report content]

---

**Review this draft:**
- Are the highlights accurate?
- Anything missing from lowlights?
- Are the quarterly goal statuses correct?
- Any metrics to add or update?

Ready to save, or would you like changes?
```

### 8. Save Final Report

After user approval:

```python
write_note_basic-memory(
    title="Monthly Review: <Month> <Year>",
    content="[final report content]",
    directory="reviews/monthly",
    tags=["review", "monthly", "YYYY-MM"]
)
```

### 9. Confirm Completion

```
## ✅ Monthly Review Complete

**Saved to:** reviews/monthly/<YYYY-MM>.md

**Summary:**
- 📈 [X] highlights captured
- 📉 [Y] lowlights documented  
- 🎯 [Z] quarterly goals tracked

**Next steps:**
- Review quarterly goals that need attention (🔴/🟡)
- Share with team/stakeholders if needed
- Set reminders for next month's priorities

Would you like me to:
- Create tasks for any action items?
- Update any quarterly goal statuses?
- Generate a presentation-ready summary?
```

## Examples

```
/monthly-review
→ Generates review for current/previous month

/monthly-review 11
→ Generates review for November of current year

/monthly-review 11 2024
→ Generates review for November 2024

/monthly-review 1 2025
→ Generates review for January 2025
```

## Notes

- The review is a **draft first** - always present for user approval before saving
- Quarterly goals table should have real goals, not placeholders
- Health status should be justified based on actual progress
- If data is sparse, note this and ask user to fill in gaps

