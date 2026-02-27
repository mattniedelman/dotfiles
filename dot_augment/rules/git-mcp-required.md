---
type: always_apply
priority: CRITICAL
description: Require all git operations to use the git MCP server, not direct process execution
last_updated: 2026-02-25
---

# Git Operations Must Use MCP Server

## CRITICAL: No Direct Git Process Execution

**All git operations MUST be performed through the git MCP server tools, never
by running `git` commands directly via `launch-process`.**

Direct git process execution is blocked by tool permissions.
Attempting to run git commands directly will result in a permission denial.

## Required Approach

Use the git MCP server tools for all git operations:

| Operation | MCP Tool |
|-----------|----------|
| Check status | `git_status_git` |
| View diff | `git_diff_unstaged_git`, `git_diff_staged_git` |
| View log | `git_log_git` |
| Stage files | `git_add_git` |
| Commit changes | `git_commit_git` |
| Create branch | `git_checkout_git` |
| List branches | `git_list_branches_git` |
| Push changes | `git_push_git` |
| Pull changes | `git_pull_git` |
| Stash changes | `git_stash_git` |

## Why This Matters

1. **Consistency** - MCP tools provide structured output that's easier to parse
2. **Safety** - MCP server has configured git identity and safe defaults
3. **Observability** - All git operations are logged through the MCP server
4. **Policy enforcement** - The MCP server can enforce additional safeguards

## Troubleshooting MCP Server Errors

**When git MCP server tools fail with schema validation errors** (like `-32602:
Structured content does not match...`), the actual error is in the server logs.

The `git_mcp_error_context.sh` hook automatically extracts recent errors from
the logs and injects them as context.
If the hook doesn't provide context, check manually:

```bash
tail -20 ~/.local/state/git-mcp-server/logs/combined.log | jq -r 'select(.level >= 50) | .errorData.originalMessage // .msg'
```

Common error causes:

- **Incorrect tool invocation** - wrong parameters, missing required fields
- **Session working directory not set** - use `git_set_working_dir_git` first
- **Server crashes or restarts** - check ToolHive status

**Schema errors almost always indicate incorrect usage**, not server bugs.
Review the parameters passed to the tool before assuming server issues.

**If errors persist**, restart the MCP server or check ToolHive status.

## Enforcement Mechanism

This rule is enforced by tool permissions in `settings.json`:

```json
{
  "toolName": "launch-process",
  "permission": {
    "type": "deny"
  },
  "shellInputRegex": "\\bgit\\s+(add|commit|push|pull|merge|rebase|reset|checkout|branch|stash|cherry-pick|revert|tag|fetch|clone|init|remote|config|diff|log|status|show)\\b"
}
```

The regex uses `\b` word boundaries to catch:

- Direct invocations:
  `git commit`
- Full path invocations:
  `/usr/bin/git commit`
- With env vars:
  `GIT_AUTHOR_NAME="x" git commit`
- In subshells and command substitutions

**Do not attempt workarounds.** If the MCP tool fails, report the issue rather
than bypassing the policy.

## Cross-Reference

Related rules:

- `git-workflow.md` - Conventional commits, branch naming, workflow processes
  (uses MCP tools)
- `core-development-rules.md` - Git commit authorization policy (uses MCP tools)
- `authorization-policies.md` - Authorization matrix for git operations (uses
  MCP tools)
