---
name: harness
description: "Use when designing domain-specific agent teams, defining specialized agents, and generating the skills they use. Trigger on 'build a harness', 'design an agent team', 'set up agents for this project', or when decomposing a complex domain into coordinated agent workflows. Also use when restructuring or extending an existing harness configuration."
---

# Harness -- Agent Team and Skill Architect

A meta-skill that analyzes a domain or project, designs a coordinated team of
specialized agents, and generates the skills each agent uses.
The output is a complete agent team configuration:
agent definitions (`.claude/agents/`), skills (`.claude/skills/`), and an
orchestrator that coordinates them.

**Core principles:**

1. Generate agent definitions and skills as files under `.claude/`
2. **Agent Teams are the default execution mode.** Use subagents only when a
   single agent works alone or inter-agent communication is unnecessary.
3. Every agent gets a definition file -- even when using built-in types

## Workflow

### Phase 1: Domain Analysis

1. Identify the domain and project from the user's request
2. Identify core task types (generation, validation, editing, analysis, etc.)
3. Check for existing agents and skills (prevent conflicts and duplication)
4. Explore the project codebase -- tech stack, data models, key modules
5. Assess user expertise from conversational cues; adjust communication level

### Phase 2: Team Architecture Design

#### 2-1. Execution Mode Selection

**Default is Agent Teams.** When 2+ agents collaborate, prefer Agent Teams.
Team members communicate directly via `SendMessage` and self-coordinate via
shared task lists (`TaskCreate`/`TaskUpdate`).
Discovery sharing, challenge, and gap-filling raise output quality.

Use subagents (the `Agent` tool) only when:

- There is exactly 1 agent
- Agents need no inter-agent communication (result hand-off only)

#### 2-2. Architecture Pattern Selection

Decompose work into specialized domains and select a team structure.
See `references/agent-design-patterns.md` for full pattern catalog.

| Pattern | When to Use |
| ------- | ----------- |
| **Pipeline** | Sequential dependent tasks |
| **Fan-out/Fan-in** | Parallel independent tasks |
| **Expert Pool** | Context-dependent selective invocation |
| **Producer-Reviewer** | Generation followed by quality review |
| **Supervisor** | Central agent with dynamic task distribution |
| **Hierarchical Delegation** | Top-down recursive decomposition |

Most real-world harnesses combine multiple patterns.

#### 2-3. Agent Separation Criteria

Evaluate along four axes:
Specialization, Parallelism, Context Load, Reusability.
Separate when domains differ and tasks can run independently.
Merge when domains overlap and context is light.

### Phase 3: Agent Definition Generation

**Every agent MUST have a definition file at
`{project}/.claude/agents/{name}.md`.** Putting role instructions directly in
the Agent tool's prompt parameter without a definition file is prohibited.
Reasons:

- Definition files enable reuse across sessions
- Team communication protocols must be explicit for collaboration quality
- The core value of a harness is separating agents (who) from skills (how)

Even built-in types (`general-purpose`, `Explore`, `Plan`) get definition files.
Specify the built-in type via the Agent tool's `subagent_type` parameter; the
definition file carries role, principles, and protocols.

**Model selection:** Choose model based on the agent's cognitive demands.

| Model | When to Use |
| ----- | ----------- |
| `opus` | Deep reasoning, architecture, ambiguity resolution |
| `sonnet` | Fast code generation, refactoring, mechanical tasks |
| `inherit` | Default. Uses the session's model. Suitable for most agents. |

**Agent type selection:**

| Situation | Recommended |
| --------- | ----------- |
| Complex role, reusable across sessions | Custom definition file |
| Web research, general tasks | `general-purpose` + definition file |
| Read-only code analysis | `Explore` + definition file |
| Planning and architecture only | `Plan` + definition file |
| File modification required | Custom definition (full tool access) |

**Required sections per definition file:**

- Core role (1-2 sentence summary)
- Responsibilities (numbered list)
- Operating principles
- Input/Output protocol (what it reads, what it produces, file paths)
- Team Communication Protocol (Agent Teams mode) -- message recipients, message
  senders, task request scope
- Error handling (failure, timeout, ambiguous input)
- Collaboration (relationships with other agents)

**QA agent requirements (when included):**

- Use `general-purpose` type, not `Explore` (Explore is read-only; QA needs to
  run verification scripts)
- QA's core job is **boundary cross-comparison**, not existence checks -- read
  API responses and front-end hooks simultaneously, compare shapes
- Run QA incrementally after each module, not once at the end
- See `references/qa-agent-guide.md` for detailed methodology

**Team reconstitution:** Only one team can be active per session, but teams can
be dissolved and reformed between phases.
Save prior team artifacts to files before dissolving.

### Phase 4: Skill Generation

Generate skills at `{project}/.claude/skills/{name}/skill.md`.
See `references/skill-authoring-guide.md` for detailed writing patterns.

**Skill structure:**

```text
skill-name/
  skill.md          (required -- YAML frontmatter + markdown body)
  references/       (optional -- conditional loading for large content)
  scripts/          (optional -- bundled executable code)
```

**Key authoring principles:**

| Principle | Detail |
| --------- | ------ |
| Explain why | Reasoning over directives. LLMs generalize from understanding. |
| Stay lean | Context window is shared. Target < 500 lines for skill.md body. |
| Generalize | Principles over narrow rules. Avoid overfitting to examples. |
| Bundle repetition | Same script every run? Pre-bundle it. |
| Command voice | "Extract the data" not "data can be extracted" |

**Description writing -- aggressive trigger induction:**

The description is the sole trigger mechanism.
Claude tends to be conservative about triggering skills, so write descriptions
aggressively.

- BAD:
  `"Processes PDF documents"`
- GOOD:
  `"PDF file reading, text/table extraction, merge, split, rotate, watermark,
  encrypt, OCR -- all PDF operations.
  If the user mentions .pdf or requests PDF output, use this skill."`

**Progressive Disclosure (3-layer loading):**

| Layer | When Loaded | Size Target |
| ----- | ----------- | ----------- |
| Metadata (name + description) | Always in context | ~100 words |
| skill.md body | On skill activation | < 500 lines |
| references/ files | On demand | Unlimited |

When skill.md approaches 500 lines, extract detail to references/ and leave a
pointer ("read this file when X").

**Skill-agent connection:**

- 1 agent uses 1-N skills (1:1 or 1:many)
- Multiple agents can share a skill
- Skills define "how"; agents define "who"

### Phase 5: Integration and Orchestration

The orchestrator is a specialized skill that coordinates the full team.
See `references/orchestrator-template.md` for templates.

**Agent Teams mode (default):**

The orchestrator uses `TeamCreate` to form the team, `TaskCreate` to assign
work, and monitors progress.
Team members self-coordinate via `SendMessage` and claim tasks from the shared
task list.

```text
[Orchestrator/Lead]
    +-- TeamCreate(team_name, members)
    +-- TaskCreate(tasks with dependencies)
    +-- Members self-coordinate (SendMessage)
    +-- Lead collects results and integrates
    +-- TeamDelete to clean up
```

**Subagent mode (lightweight):**

The orchestrator calls `Agent` directly.
Subagents return results to the orchestrator only -- no inter-agent
communication.

```text
[Orchestrator]
    +-- Agent(agent-1, run_in_background=true)
    +-- Agent(agent-2, run_in_background=true)
    +-- Collect results
    +-- Integrate into final output
```

**Data passing protocol:**

| Strategy | Method | Mode | Best For |
| -------- | ------ | ---- | -------- |
| Message | `SendMessage` between members | Teams | Coordination |
| Task | `TaskCreate`/`TaskUpdate` | Teams | Dependencies |
| File | Write/read at agreed paths | Both | Large artifacts |

File-based conventions:

- Create `_workspace/` under the working directory for intermediate artifacts
- Name files:
  `{phase}_{agent}_{artifact}.{ext}`
- Preserve `_workspace/` after completion (audit trail, post-verification)
- Final deliverables go to user-specified output path

**Error handling:**

- 1 retry on failure; if retry fails, proceed without that result
- Note missing results in the final output
- Conflicting data:
  cite both sources, never silently discard
- If majority of agents fail, ask the user whether to proceed

**Team size guidelines:**

| Scope | Recommended Members | Tasks per Member |
| ----- | ------------------- | ---------------- |
| Small (5-10 tasks) | 2-3 | 3-5 |
| Medium (10-20 tasks) | 3-5 | 4-6 |
| Large (20+ tasks) | 5-7 | 4-5 |

3 focused members outperform 5 unfocused members.

### Phase 6: Validation and Testing

#### 6-1. Structural Validation

- All agent definition files exist at `.claude/agents/`
- Skill frontmatter (name, description) is valid
- Cross-references between agents are consistent
- No commands generated in `.claude/commands/`

#### 6-2. Execution Mode Verification

- Agent Teams mode:
  member communication paths, task dependencies, team size
- Subagent mode:
  input/output connections, `run_in_background` settings

#### 6-3. Skill Execution Test

For each generated skill:

1. Write 2-3 realistic test prompts (what a real user would type)
2. Run with-skill vs without-skill comparison via subagents
3. Evaluate output quality (assertion-based where objective, user review where
   subjective)
4. Iterate:
   generalize feedback into skill edits, re-test
5. If agents recreate the same helper script across runs, bundle it in scripts/

#### 6-4. Trigger Verification

For each skill's description:

1. Write 8-10 should-trigger queries (formal, casual, explicit, implicit)
2. Write 8-10 should-NOT-trigger queries -- near-miss queries with keyword
   overlap but wrong intent (not obviously unrelated queries)
3. Verify no trigger collisions with existing skills

#### 6-5. Dry-Run Test

- Orchestrator phase order is logically sound
- Data passing has no dead links (every input has a producing output)
- Error scenarios have viable fallback paths
- Add a `## Test Scenarios` section:
  1 happy path + 1 error path minimum

## Output Checklist

After generation, verify:

- [ ] `.claude/agents/` -- agent definition files (even for built-in types)
- [ ] `.claude/skills/` -- skill files (skill.md + references/)
- [ ] One orchestrator skill (data flow + error handling + test scenarios)
- [ ] Execution mode stated (Agent Teams or subagent)
- [ ] All Agent definitions specify an appropriate `model:` value
- [ ] `.claude/commands/` -- nothing generated
- [ ] No conflicts with existing agents or skills
- [ ] Skill descriptions are aggressively worded for reliable triggering
- [ ] skill.md bodies under 500 lines; overflow moved to references/
- [ ] Execution test with 2-3 prompts completed
- [ ] Trigger verification (should-trigger + should-NOT-trigger) completed

## References

- Architecture patterns:
  `references/agent-design-patterns.md`
- Orchestrator templates:
  `references/orchestrator-template.md`
- Skill authoring guide:
  `references/skill-authoring-guide.md`
