# Augment Agent Rules Directory

This directory contains rules and guidelines that govern the behavior of the
Augment AI assistant.

## CLI Command Name

**IMPORTANT:** The Augment CLI command is `auggie`, NOT `augment`.

- ✅ Correct:
  `auggie`, `auggie --help`, `auggie chat`
- ❌ Incorrect:
  `augment`, `augment --help`

When referring to the product/company, use "Augment".
When referring to the CLI command, use `auggie`.

## Quick Reference: Priority Levels

| Priority | Type | Enforcement | Files |
|----------|------|-------------|-------|
| **CRITICAL** | `always_apply` | Violations are penalized | `response-style-communication.md`, `core-development-rules.md` (includes Notes Management), `git-mcp-required.md`, `github-mcp-required.md` |
| **HIGH** | `always_apply` | Always active for relevant domains | `git-workflow.md`, `linting-enforcement.md`, `environment.md`, `security.md`, `helm-kubernetes-guidelines.md`, `python-development.md`, `authorization-policies.md`, `shell-commands.md` |
| **STANDARD** | `agent_requested` | Guidance for specific scenarios | (migrated to skills) |

---

## Rule Conflict Resolution

When rules appear to conflict, apply this precedence:

1. **CRITICAL rules always take precedence** over HIGH and STANDARD rules
2. **Explicit user requests override default rules** (except security-critical
   operations)
3. **More specific rules override general rules** (e.g., Python-specific rules
   override general coding rules)
4. **Scope constraints always apply** - never do more than asked, even if rules
   suggest it
5. **Security rules cannot be overridden** by user requests (secrets, SQL
   injection, etc.)

### Common Conflict Resolutions

| Conflict | Resolution |
|----------|------------|
| Auto-fix linting vs. scope limits | Only auto-fix in files being modified for user's request |
| Small refactoring allowed vs. no unsolicited work | Small refactoring only within scope of user's request |
| Proactive notes vs. no unsolicited files | Notes are allowed; documentation files are not |
| User says "fix it" vs. authorization required | Ask for clarification on what "fix" means |

---

## CRITICAL Priority (Violations are Penalized)

These rules are enforced with the same severity as scope violations:

### 1. response-style-communication.md

- NEVER use evaluative language ("Great question!", "Excellent idea!")
- Direct, professional responses without flattery
- Objective language in all code and documentation

### 2. core-development-rules.md

- **Tool Selection**:
  ALWAYS use semantic tools for code symbols (never grep/ripgrep)
- **Git Operations**:
  ALWAYS use git MCP server tools (see `git-mcp-required.md`)
- **Git Commits**:
  NEVER commit without explicit authorization
- **Code Patterns**:
  No nested functions, no continue statements
- **Tool Behavior Verification**:
  ALWAYS verify CLI tool arguments/defaults before use (e.g., check if pyright
  needs explicit directory)

### 3. git-mcp-required.md

- **All git operations MUST use the git MCP server tools**
- Direct `git` commands via `launch-process` are blocked by tool permissions
- Use `git_status_git`, `git_commit_git`, `git_diff_git`, etc.

### 4. github-mcp-required.md

- **Parse GitHub URLs** and use appropriate MCP tools or gh CLI
- **NEVER use `web-fetch`** for github.com or raw.githubusercontent.com
- Use `pull_request_read_github`, `issue_read_github`, `get_commit_github`, etc.
- Fallback to `gh` CLI for workflow runs and job logs

### 5. Notes Management (in core-development-rules.md) -- CRITICAL

- **Session Start**:
  MUST check basic-memory when user mentions a project, prior work, or decisions
- **Task Completion**:
  MUST evaluate notes update after completing significant work
- **End of Session**:
  MUST review if new knowledge, changed decisions, or stale notes exist
- **Failure to update notes when triggers are met is a violation**

---

## HIGH Priority (Always Apply When Relevant)

### 6. git-workflow.md

- Conventional Commits format
- Branch naming conventions
- Commit authorization workflow
- **All git operations use MCP server tools** (see `git-mcp-required.md`)

### 7. linting-enforcement.md

- Run linters after code changes:
  ast-grep → ruff → ty
- Prefer ty over mypy for type checking
- Fix errors rather than suppress
- Approval required for suppressions

### 8. environment.md

- Path resolution rules
- Workspace structure
- Tool management (mise)

### 9. security.md

- Never hardcode secrets
- Authorization for security-related changes
- SQL injection prevention

### 10. helm-kubernetes-guidelines.md

- CRITICAL:
  Never manage namespaces in Helm charts
- Chart structure and values organization

### 11. python-development.md

- Package management:
  uv (default) or poetry (if poetry.lock exists)
- Authorization required for package installation
- Testing with pytest, type hints required

### 12. authorization-policies.md

- Unified authorization matrix for all operations
- Defines EXPLICIT, CONFIRM, SUGGEST, ALLOWED, REFUSE levels
- Single source of truth for permission requirements

### 13. Structured Thinking (in core-development-rules.md)

- Use think-strategies for complex debugging, architecture, investigations
- Skip for simple, well-defined tasks

---

## Frontmatter Schema

All rule files should include this frontmatter:

```yaml
type: always_apply | agent_requested
priority: CRITICAL | HIGH | STANDARD
description: Brief description of the rule's purpose
last_updated: YYYY-MM-DD
---
```

## Adding New Rules

1. Create file with proper frontmatter (see schema above)
2. Use clear section headers and concise examples
3. Update this README with the new rule's priority level
4. Cross-reference related rules where appropriate

## Rule Enforcement

The AI assistant is evaluated on:

- **CRITICAL rule adherence** (heavily penalized for violations)
- **Completeness** (missing downstream changes is a failure)
- **Scope adherence** (no unsolicited work)
- **File creation discipline** (only when necessary)
