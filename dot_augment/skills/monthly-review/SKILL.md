---
name: monthly-review
description: Use when generating monthly review reports for engineering leadership - highlights, lowlights, strategic goals, and quarterly goal tracking
---

# Monthly Review

This skill generates structured monthly review reports matching the format used
in engineering leadership presentations.

## When to Use

Use this skill when:

- End of month review is needed
- User wants to prepare a monthly product/engineering review
- Quarterly goals need progress tracking
- User asks for "monthly review", "monthly report", "month summary"

## Report Structure

### Section 1: State of the Business

1. **Highlights** - Brief bullet points of accomplishments
   - Keep each bullet concise (1-2 lines max)
   - Focus on shipped features, completed milestones, key decisions
   - Sub-bullets for related items (e.g., post-v1 tasks)

2. **Lowlights** - Brief description of challenges
   - Usually 1-2 items max
   - Focus on blockers or significant issues
   - Keep it factual, not elaborate

3. **Key Metric Changes**
   - Only notable metric changes
   - If nothing significant:
     "None"
   - Don't fabricate metrics

4. **Strategic Goals (Forward Looking Priorities)**
   - What's coming next
   - Connection to broader strategy
   - Brief bullet points

### Section 2: Quarterly Tactical Goals

| Goal | Associated Strategic Goal | Changes from Last Month | Status | Follow-Ups |
|------|--------------------------|-------------------------|--------|------------|
| [Goal name] | [Strategic goal it maps to] | [What changed this month] | [Status] | [What's next] |

**Status Values:**

- `Done` - Completed
- `Done (v1)` - First version shipped, more work planned
- `Done-ish` - Mostly done, ongoing support/maintenance
- `In Progress` - Actively being worked on
- `Planning` - Not started, in planning phase
- `Blocked` - Cannot progress due to external dependency

**Note:** RYG (Red/Yellow/Green) indicators are optional and typically only
shown when presenting to leadership who expects them.

## Data Gathering Process

### 1. Determine Review Period

- Default:
  Current month or most recent completed month
- Use explicit month/year if provided by user

### 2. Gather Data from Basic Memory

```python
# Get recent activity
recent_activity_basic - memory(timeframe="30 days")

# Search for completed work
search_notes_basic - memory(query="completed done finished shipped")

# Search for decisions made
search_notes_basic - memory(query="decision decided")

# Search for challenges/issues
search_notes_basic - memory(query="blocked issue problem challenge")
```

### 3. Check for Quarterly Goals

```python
search_notes_basic - memory(query="quarterly goals tactical goals strategic goals")
```

If not found, prompt user to provide them.

### 4. Optionally Gather GitHub Data

Only if specifically requested or relevant to the review:

```python
search_pull_requests_github(
    query="is:merged author:@me merged:>YYYY-MM-01", owner="imprivata-ai"
)
```

**Note:** GitHub PR data is typically NOT included in the presentation unless
there's a specific reason (e.g., metrics review, team velocity discussion).
The GitHub MCP server is read-only.

## Report Template

```markdown
# Monthly Review: <Month> <Year>

## State of the Business

### Highlights
- [Brief accomplishment 1]
- [Brief accomplishment 2]
  - [Sub-detail if needed]
  - [Sub-detail if needed]
- [Brief accomplishment 3]

### Lowlights
- [Brief challenge or blocker]

### Key Metric Changes
- [Metric change, or "None" if nothing notable]

## Strategic Goals (Forward Looking Priorities)
- [Forward-looking priority 1]
- [Forward-looking priority 2]
- [Forward-looking priority 3]

## Quarterly Tactical Goals

| Goal | Associated Strategic Goal | Changes from Last Month | Status | Follow-Ups |
|------|--------------------------|-------------------------|--------|------------|
| [Goal 1] | [Strategic Goal] | [What changed] | Done (v1) | [Next steps] |
| [Goal 2] | [Strategic Goal] | [What changed] | In Progress | [Next steps] |
| [Goal 3] | [Strategic Goal] | [What changed] | Planning | [Next steps] |
```

## Best Practices

1. **Be concise** - This is a presentation, not a detailed report
2. **Bullet points** - Not paragraphs
3. **One lowlight is fine** - Don't fabricate problems
4. **Status should be honest** - "Done-ish" is a valid status
5. **Follow-ups are forward-looking** - What will you do next?
6. **Don't over-engineer** - Match the actual presentation format

## Saving the Review

After user approves the draft:

```python
write_note_basic - memory(
    title="Monthly Review - <Month> <Year>",
    content="[report content]",
    directory="journal/reviews",
    tags=["review", "monthly", "YYYY-MM", "presented"],
)
```

## Example Output

Based on an actual February 2026 review:

```markdown
## State of the Business

### Highlights
- Proposed ADR for Data Fabric API design
- Alert Summarizer post-v1 tasks wrapping up:
  - Adding per-request cost limiting (in review)
  - Adding revised tag and scoring structure (in progress)
  - Added message caching to Bedrock calls for cost reduction
- Workstation Clustering post-v1 tasks wrapping up:
  - Results sending to Verosint (done in dev)
  - Added "risk" score (PR approved, going to dev)
- Built an Agentic AI project to analyze EAM Salesforce cases

### Lowlights
- Bug in LLM gateway breaks Bedrock caching with no workaround

### Key Metric Changes
- None

## Strategic Goals (Forward Looking Priorities)
- Developing 2026 roadmap with Zach
- EAM Healthcheck Agent implementation starting soon
- Building out alert summarizer platform for other products
- Working with AIP on customer clone for testing

## Quarterly Tactical Goals

| Goal | Associated Strategic Goal | Changes from Last Month | Status | Follow-Ups |
|------|--------------------------|-------------------------|--------|------------|
| Maize Shim | Operational Efficiency | Continuing to advise | Done-ish | Advise as needed |
| EAM Workstation Clustering | Market Differentiation | Post-v1 changes in review | Done (v1) | Promote to QA/prod |
| Alert Summarizer | Market Differentiation | Post-v1 changes in progress | Done (v1) | Continue post-v1 changes |
```
