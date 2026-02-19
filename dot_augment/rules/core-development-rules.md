---
type: always_apply
priority: CRITICAL
description: Core development rules and coding standards for Matt's workflow
last_updated: 2025-02-13
---
# Core Development Rules

## ⚠️ CRITICAL RULES SUMMARY ⚠️

Before proceeding with any task, be aware of these **CRITICAL FAILURE**
violations:

1. **Response Style (MANDATORY)**:
   NEVER use flattering, evaluative, or self-aggrandizing language in responses.
   No "Great question!", "Excellent idea!", "That's interesting!", etc. See
   `response-style-communication.md` for complete list of prohibited phrases.

2. **Tool Selection (MANDATORY)**:
   ALWAYS use specialized semantic code analysis tools (`find_symbol`,
   `find_referencing_symbols`, `find_implementations`, `get_symbols_overview`)
   when searching for code symbols.
   NEVER use `grep`, `ripgrep`, `ag`, or `ack` for code symbol searches.
   See "Tool Selection Hierarchy" section below.

3. **Git Operations (MANDATORY)**:
   ALL git operations MUST use the git MCP server tools (e.g., `git_status_git`,
   `git_commit_git`, `git_add_git`).
   Direct `git` commands via `launch-process` are blocked.
   See `git-mcp-required.md`.

4. **Git Commits**:
   NEVER commit without explicit user authorization using the word "commit"

5. **Git Staging (MANDATORY)**:
   NEVER use `git_add_git` with `all:
   true` - ALWAYS stage specific files explicitly with exact paths

6. **No Nested Functions**:
   NEVER define functions inside other functions or create closures

7. **No Continue Statements**:
   NEVER use `continue` statements in loops

---

## Code Patterns (Automated Enforcement)

All code patterns are **automatically enforced** by ast-grep rules in
`~/.config/ast-grep/rules/` (70+ rules) and ruff.
The `auto_lint.sh` hook runs these on every file modification.

**Key enforced patterns:**

- No nested functions, classes, or closures
- No `continue`, `global`, or `nonlocal` statements
- No ternary expressions
- No mocks (`unittest.mock`, `pytest-mock`, `monkeypatch`)
- No `assert x == True/False`
- No `time.sleep` in tests
- No dataclasses (use Pydantic)
- No legacy typing (`List`, `Optional`) - use modern syntax
- No `os.path` - use pathlib

See individual rule files for rationale and alternatives.

## Tool Selection Hierarchy

### ⚠️ MANDATORY: Semantic Tools for Code Symbols ⚠️

**CRITICAL FAILURE** to use generic text search (`grep`, `ripgrep`, `ag`, `ack`)
for code symbols when semantic tools are available.

| Search Target | Required Tool | Fallback (justify use) |
|--------------|---------------|------------------------|
| Symbol definitions | `find_symbol` | Never for code symbols |
| Symbol usages | `find_referencing_symbols` | Never for code symbols |
| Implementations | `find_implementations` | Never for code symbols |
| File structure | `get_symbols_overview` | Never for code symbols |
| Comments, TODOs | `view` with `search_query_regex` | `grep`/`ripgrep` |
| Config files (YAML, JSON) | `grep`/`ripgrep` | - |
| String literals, logs | `grep`/`ripgrep` | - |

### Decision Rule

**Before ANY search**:
Is the target a code symbol (class, function, variable, method)?

- **YES** → MUST use semantic tools.
  No exceptions.
- **NO** → May use text search.

### Prohibited Patterns

- ❌ `grep -r "class ClassName"` or `ripgrep "def function_name"`
- ❌ Text search for "all usages of" any code symbol
- ❌ Justifying text search with "it's faster" or "it's simpler"

## Structured Thinking

For complex debugging, architecture, or investigations, use the
`structured-thinking` skill (on-demand) rather than direct action.
See the skill for strategy selection and usage guidance.

### Using Think-Strategies Effectively

**Session management**:

- Use `think-session-manager` to resume prior thinking sessions on ongoing
  problems
- Search for related sessions before starting new investigations
- Persist sessions for complex problems that may span multiple conversations

**Integration with other tools**:

- Use `plannedActions` to queue tool calls that will inform the next thought
- Use `actionResults` to incorporate tool outputs into reasoning
- Combine with basic-memory to document conclusions and decisions

**Quality reflection**:

- Use the `qualityRating` field to self-assess reasoning quality
- Adjust approach if ratings indicate poor fit between strategy and problem

### Examples

```text
❌ Task: "Add a created_at field to the User model"
   → Direct action. Simple, well-defined, low-risk.

✅ Task: "Figure out why the payment processing is sometimes failing"
   → Use react strategy. Multiple hypotheses, need to investigate and refine.

❌ Task: "Update the README with the new API endpoint"
   → Direct action. Straightforward documentation update.

✅ Task: "Design the caching layer for the API"
   → Use tree_of_thoughts. Multiple valid approaches (Redis, in-memory, CDN),
     need to evaluate tradeoffs.

❌ Task: "Run the tests and fix any failures"
   → Direct action initially. Escalate to structured thinking if failures
     are complex or interconnected.

✅ Task: "Migrate from REST to GraphQL without breaking existing clients"
   → Use rewoo strategy. Complex multi-step migration requiring careful
     planning before execution.
```

## Deep Modules and Simple Interfaces

### Interface Design

- **Rule**:
  Create deep modules with simple, powerful interfaces that hide complex
  implementation details
- **Rationale**:
  Based on "A Philosophy of Software Design" - minimize cognitive load while
  maximizing functionality
- **Implementation**:
  - Few public methods with clear, intuitive names
  - Hide implementation complexity behind clean abstractions
  - Provide sensible defaults to reduce parameter burden

### API Consolidation

- **Rule**:
  Consolidate related functionality into cohesive modules rather than
  fragmenting across multiple small modules
- **Rationale**:
  Reduces the number of interfaces developers need to learn and maintain
- **Example**:
  Prefer one client class with multiple methods over multiple specialized client
  classes

## Complexity Management

### Avoid Shallow Modules

- **Rule**:
  Don't create modules that provide little functionality relative to their
  interface complexity
- **Rationale**:
  Shallow modules increase overall system complexity without proportional
  benefit
- **Test**:
  If a module's interface is nearly as complex as its implementation, consider
  refactoring

### Strategic vs Tactical Programming

- **Rule**:
  Always consider long-term design implications, not just immediate
  implementation needs
- **Implementation**:
  - Design APIs that can evolve without breaking changes
  - Choose general-purpose solutions over highly specialized ones
  - Invest time in proper abstractions upfront

### Remove Unnecessary Complexity

- **Rule**:
  Actively eliminate complexity that doesn't provide proportional value
- **Examples**:
  - Remove redundant processing passes
  - Consolidate similar logic patterns
  - Eliminate configuration options that serve edge cases
  - Use built-in solutions over custom implementations when possible

## Python-Specific Best Practices

### Type Hints and Documentation

- **Rule**:
  Use type hints for all public functions and class methods (enforced by
  pyright/zuban)
- **Documentation**:
  Include docstrings for all public APIs explaining purpose, parameters, and
  return values

### Error Handling

- Prefer specific exception types over generic Exception
- Include meaningful error messages with context
- Use logging consistently (avoid mixing print, console.print, etc.)

### Comment Placement

- Write comments on their own line(s) above the code they describe
- Avoid inline comments that cause line length issues

## Package Management

**Primary Reference**:
See `python-development.md` for detailed Python package management.

### Quick Reference

| Lock File Present | Use Package Manager |
|-------------------|---------------------|
| `poetry.lock` | Poetry |
| `uv.lock` or none | uv (default) |

**CRITICAL**:
Never bypass lock files with low-level commands (`pip install`, `uv pip
install`).

**Non-Python Languages**:
Use appropriate package managers (npm/yarn/pnpm for JS, cargo for Rust, go mod
for Go).
Never manually edit package files when commands are available.
See `authorization-policies.md` for installation authorization requirements.

## Testing and Quality

See the `test-driven-development` skill for detailed testing patterns including:

- AAA (Arrange, Act, Assert) pattern
- Test documentation guidelines
- Avoiding mocks (use real implementations or fakes)
- Fuzzing with Polyfactory, Hypothesis, Faker
- Boolean assertion patterns

**Key rules (enforced by ast-grep):**

- No `unittest.mock`, `pytest-mock`, or `monkeypatch`
- No `time.sleep` in tests
- No `assert x == True/False`

**Linting:** See `linting-enforcement.md` for workflow.

## Code Organization

### Single Responsibility Principle

- **Rule**:
  Each module, class, and function should have a single, well-defined
  responsibility
- **Implementation**:
  - Functions should do one thing well
  - Classes should represent cohesive concepts
  - Modules should group related functionality

### Consistent Naming Conventions

- **Rule**:
  Use consistent, descriptive naming throughout the codebase
- **Implementation**:
  - Use snake_case for variables and functions
  - Use PascalCase for classes
  - Use UPPER_CASE for constants
  - Choose names that clearly indicate purpose and scope

### Configuration Management

- **Rule**:
  Centralize configuration and avoid magic numbers scattered throughout code
- **Implementation**:
  - Use configuration files or environment variables
  - Define constants at module level for magic numbers
  - Provide sensible defaults for optional configuration
  - Document configuration options clearly

## Version Control Practices

**CRITICAL:
All git operations MUST use the git MCP server tools.** Direct `git` commands
via `launch-process` are blocked by tool permissions.
See `git-mcp-required.md` for the complete tool reference.

### ⚠️ CRITICAL: Git Commit Authorization Policy ⚠️

**ABSOLUTE RULE**:
The AI assistant must NEVER execute `git_commit_git`, `git_push_git`, or any git
MCP tool that modifies repository history without EXPLICIT user authorization.

**"Explicit authorization" means:**

- User must use the word "commit", "push", "merge", "rebase", or equivalent git
  operation term
- Phrases like "save", "finish", "complete", "done" do NOT constitute
  authorization
- When in doubt, DO NOT commit - instead ask the user

**Before ANY commit:**

1. Confirm you have explicit authorization
2. Present the proposed commit message to the user
3. Wait for user approval
4. Only then execute the commit

**Violation of this policy is a critical failure.**

---

### Git Commits

- **Rule**:
  Only perform git commits when explicitly requested by the user
- **Rationale**:
  Committing code is a deliberate action that should be under the user's control
  and timing
- **Implementation**:
  - **NEVER** automatically commit changes after making edits
  - **NEVER** commit as part of a workflow, even if it seems like a natural
    completion step
  - **NEVER** proactively suggest or ask to commit unless the user has
    explicitly mentioned committing
  - **ONLY** commit when the user explicitly uses commit-related commands (see
    examples below)
  - When explicitly asked to commit, ALWAYS confirm the commit message with the
    user before executing

### What Constitutes an Explicit Commit Request

**Valid commit requests (these authorize commits):**

- "Commit these changes"
- "Make a commit with message X"
- "Git commit this"
- "Commit the changes with message:
  feat(api):
  add new endpoint"
- "Stage and commit these files"

**Invalid/ambiguous phrases (these do NOT authorize commits):**

- "Save this" / "Save my work" / "Save these changes"
- "Finish this feature" / "Complete this task"
- "We're done here" / "That's good"
- "Push this to the repo" (requires separate explicit commit request first)
- "Create a PR" (requires separate explicit commit request first)
- "Make this permanent"
- Any phrase that doesn't explicitly use the word "commit" or "git commit"

**When in doubt**:
If the user's request doesn't explicitly mention "commit" or "committing," do
NOT commit.
Instead, inform the user that changes have been made and are ready to commit
when they choose to do so.

### Git MCP Operations Requiring Explicit Permission

The following git MCP operations **REQUIRE explicit user permission** and must
NEVER be performed automatically:

**Prohibited without explicit permission:**

- `git_commit_git` - Creating commits
- `git_push_git` - Pushing to remote repositories
- `git_merge_git` - Merging branches
- `git_rebase_git` - Rebasing commits (including interactive rebase)
- `git_cherry_pick_git` - Cherry-picking commits
- `git_reset_git` with `mode:
  "hard"` - Hard resets that discard changes
- `git_clean_git` - Removing untracked files
- `git_branch_git` with `operation:
  "delete"` and `force:
  true` - Force deleting branches
- `git_tag_git` with `mode:
  "create"` - Creating tags

**Allowed without explicit permission (read-only or safe operations):**

- `git_status_git` - Checking repository status
- `git_diff_git` - Viewing differences
- `git_log_git` - Viewing commit history
- `git_branch_git` with `operation:
  "list"` - Listing branches
- `git_show_git` - Showing commit details
- `git_fetch_git` - Fetching from remote (doesn't modify working tree)

**Requires explicit permission but can be suggested:**

- `git_add_git` - Staging files (can suggest:
  "These files are ready to stage.
  Would you like me to stage them?")
- `git_checkout_git` - Switching branches (can suggest if user asks to work on
  different branch)
- `git_stash_git` - Stashing changes (can suggest if needed for branch
  switching)

**Critical rule**:
When user requests an operation that requires a prerequisite git operation
(e.g., "push this" requires committing first), AI must:

1. Inform user of the prerequisite
2. Request explicit permission for each operation separately
3. Never assume permission for prerequisites

### Workflow Completion and Commits

**Critical Rule**:
Workflow completion phrases do NOT authorize commits.

**Phrases that complete work but do NOT authorize commits:**

- "Finish this feature"
- "Complete this task"
- "We're done with this"
- "That's everything"
- "Implement feature X" (even if implementation is complete)
- "Fix bug Y" (even if fix is complete)
- "Wrap this up"
- "Finalize the changes"

**Correct AI behavior when work is complete:**

1. Complete all requested code changes
2. Run tests if requested
3. Inform user:
   "I've completed [description of work].
   The changes are ready to commit when you're ready.
   Would you like me to commit these changes?"
4. Wait for explicit commit authorization

**Exception**:
If user's original request explicitly included committing (e.g., "Implement
feature X and commit it"), then commit authorization is included.
However, AI should still confirm the commit message before executing.

**When user says "finish" or "complete":**

- Interpret as:
  finish the code changes only
- Do NOT interpret as:
  finish everything including committing
- After completing code changes, remind user that changes are uncommitted

### Objective Language in Code and Documentation

**Rule**:
Use objective, factual language in all code-related content.
See `response-style-communication.md` for comprehensive guidelines.

**Quick reference:**

- ❌ "Greatly improve error handling" → ✅ "Refactor error handling to use custom
  exception types"
- ❌ "Add amazing new feature" → ✅ "Add user authentication feature"
- ❌ "Perfect the API design" → ✅ "Simplify API by consolidating endpoints"

### GitHub API Operations

Use the `github-api` tool for all remote GitHub operations.
Never use `web-fetch` for GitHub URLs.
See the `github-workflow` skill for detailed API reference and patterns.

**Key rules:**

- ALWAYS use `github-api` for PRs, issues, CI status, releases
- NEVER use `web-fetch` for github.com or raw.githubusercontent.com
- Use `gh` CLI only as documented fallback

## Notes Management

See the `knowledge-capture` skill for detailed notes guidance including:

- Mandatory triggers (session start, task completion, end of session)
- What to capture and what to avoid
- Person note formatting

**Critical requirement:** MUST check basic-memory at session start when context
likely exists.
MUST evaluate notes update after completing significant work.

**Failure to update notes when triggers are met is a CRITICAL violation.**
