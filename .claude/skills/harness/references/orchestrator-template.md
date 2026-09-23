# Orchestrator Skill Templates

The orchestrator binds individual agents and skills into a coordinated workflow.
Phase 4 skills define "what each agent does." The orchestrator defines "who runs
when, in what order, and how results connect."

---

## Template A: Agent Teams Mode (Default)

````markdown
---
name: {domain}-orchestrator
description: "{Domain} agent team orchestrator. Coordinates {N} members to
  produce {deliverable}. {Trigger keywords}."
---

# {Domain} Orchestrator

Coordinates the {domain} agent team to produce {deliverable}.

## Execution Mode: Agent Teams

## Agent Roster

| Member | Agent Type | Role | Skill | Output |
| ------ | ---------- | ---- | ----- | ------ |
| {member-1} | {custom or built-in} | {role} | {skill} | {output-file} |
| {member-2} | {custom or built-in} | {role} | {skill} | {output-file} |

## Workflow

### Phase 1: Preparation

1. Analyze user input -- {what to extract}
2. Create `_workspace/` under the working directory
3. Save input data to `_workspace/00_input/`

### Phase 2: Team Formation

1. Create team:
   TeamCreate(
     team_name: "{domain}-team",
     members: [
       { name: "{member-1}", agent_type: "{type}",
         model: "{inherit|opus|sonnet}",
         prompt: "{role and task instructions}" },
       { name: "{member-2}", agent_type: "{type}",
         model: "{inherit|opus|sonnet}",
         prompt: "{role and task instructions}" },
     ]
   )

2. Register tasks:
   TaskCreate(tasks: [
     { title: "{task-1}", description: "{detail}", assignee: "{member-1}" },
     { title: "{task-2}", description: "{detail}", assignee: "{member-2}" },
     { title: "{task-3}", description: "{detail}", depends_on: ["{task-1}"] },
   ])

   Target 5-6 tasks per member. Use depends_on for sequencing.

### Phase 3: {Primary Work}

Members self-coordinate via the shared task list and SendMessage.
Lead monitors progress and intervenes when needed.

**Communication rules:**
- {member-1} sends {info type} to {member-2} via SendMessage
- {member-2} saves results to file and notifies lead on completion
- Members request info from each other via SendMessage as needed

**Artifact storage:**

| Member | Output Path |
| ------ | ----------- |
| {member-1} | `_workspace/{phase}_{member-1}_{artifact}.md` |
| {member-2} | `_workspace/{phase}_{member-2}_{artifact}.md` |

**Lead monitoring:**
- Idle members trigger auto-notification
- Use TaskGet to check overall progress
- SendMessage to redirect stuck members or reassign work

### Phase 4: {Integration}

1. Wait for all member tasks to complete (TaskGet)
2. Read each member's artifacts
3. {Integration/verification logic}
4. Generate final deliverable: `{output-path}/{filename}`

### Phase 5: Cleanup

1. SendMessage to members requesting shutdown
2. TeamDelete to dissolve team
3. Preserve `_workspace/` (do not delete)
4. Report summary to user

## Error Handling

| Situation | Strategy |
| --------- | -------- |
| 1 member fails | Detect -> SendMessage -> restart or replace |
| Majority fail | Inform user, ask whether to proceed |
| Timeout | Use partial results, terminate remaining members |
| Data conflicts | Cite both sources, never discard |

## Test Scenarios

### Happy Path
1. User provides {input}
2. Phase 2 forms team ({N} members, {M} tasks)
3. Phase 3: members self-coordinate and produce artifacts
4. Phase 4: lead integrates into final deliverable
5. Expected: `{output-path}/{filename}`

### Error Path
1. Phase 3: {member-2} errors and stops
2. Lead receives idle notification
3. SendMessage to check status -> restart attempt
4. Restart fails -> reassign {member-2}'s tasks to {member-1}
5. Final output notes "{member-2} area partially incomplete"
````

---

## Template B: Subagent Mode (Lightweight)

````markdown
---
name: {domain}-orchestrator
description: "{Domain} orchestrator. Coordinates {N} agents to produce
  {deliverable}. {Trigger keywords}."
---

# {Domain} Orchestrator

Coordinates {domain} agents to produce {deliverable}.

## Execution Mode: Subagents

## Agent Roster

| Agent | subagent_type | Role | Skill | Output |
| ----- | ------------- | ---- | ----- | ------ |
| {agent-1} | {type} | {role} | {skill} | {output-file} |
| {agent-2} | {type} | {role} | {skill} | {output-file} |

## Workflow

### Phase 1: Preparation

1. Analyze user input -- {what to extract}
2. Create `_workspace/`
3. Save input data to `_workspace/00_input/`

### Phase 2: {Primary Work}

**Execution: {parallel | sequential | conditional}**

{Parallel:}
Dispatch all agents simultaneously:

| Agent | Input | Output | run_in_background |
| ----- | ----- | ------ | ----------------- |
| {agent-1} | {source} | `_workspace/{phase}_{agent}_{artifact}.md` | true |
| {agent-2} | {source} | `_workspace/{phase}_{agent}_{artifact}.md` | true |

{Sequential:}
1. Agent-1 -> `_workspace/01_{artifact}.md`
2. Agent-2 (reads 01 output) -> `_workspace/02_{artifact}.md`

### Phase 3: {Integration}

1. Read Phase 2 artifacts
2. {Integration logic}
3. Final deliverable: `{output-path}/{filename}`

### Phase 4: Cleanup

1. Preserve `_workspace/`
2. Report summary to user

## Error Handling

| Situation | Strategy |
| --------- | -------- |
| 1 agent fails | Retry once. On second failure, proceed without. Note gap. |
| Majority fail | Inform user, ask whether to proceed |
| Timeout | Use partial results |
| Data conflicts | Cite both sources |

## Test Scenarios

### Happy Path
1. User provides {input}
2. {N} agents run in parallel, each produces artifact
3. Integration produces final deliverable
4. Expected: `{output-path}/{filename}`

### Error Path
1. {agent-2} fails, retry fails
2. Proceed with remaining results
3. Final output notes "{agent-2} data unavailable"
````

---

## Authoring Principles

1. **State execution mode up front** -- Agent Teams or subagents
2. **Agent Teams:
   specify TeamCreate/SendMessage/TaskCreate usage concretely**
3. **Subagents:
   specify all Agent tool parameters** -- name, subagent_type, prompt,
   run_in_background
4. **Use absolute file paths** -- relative paths confuse cross-agent references
5. **Declare phase dependencies** -- which phase consumes which output
6. **Make error handling realistic** -- do not assume everything succeeds
7. **Include test scenarios** -- 1 happy path + 1 error path minimum
