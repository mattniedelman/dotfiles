---
type: always_apply
priority: HIGH
description: Critical git constraints - MCP tools, staging rules, authorization
last_updated: 2026-02-19
---

# Git Workflow - Critical Constraints

For detailed conventions (commits, branches, PRs), see the `git-workflow` skill.

## CRITICAL: Use Git MCP Server Tools

**All git operations MUST use git MCP server tools.** Direct `git` commands via
`launch-process` are blocked.

See `git-mcp-required.md` for complete tool reference.

## CRITICAL: Staging Rules

**NEVER use `git_add_git` with `all:
true`** - stages all changes indiscriminately.

**ALWAYS stage specific files:**

```javascript
git_add_git({ files: ["path/to/file1.py", "path/to/file2.py"] })
```

**Before committing:** Review staged files with `git_status_git`.

**Exception:** None.
Always use explicit file paths.

## Authorization Requirements

| Operation | Authorization | Notes |
|-----------|---------------|-------|
| `git_commit_git` | EXPLICIT | Must confirm message first |
| `git_push_git` | EXPLICIT | Requires commit first |
| `git_merge_git` | EXPLICIT | History-modifying |
| `git_rebase_git` | EXPLICIT | Rewrites history |
| `git_reset_git` (hard) | EXPLICIT | Destructive |
| `git_add_git` | SUGGEST | Suggest files, never auto-stage all |

## Commit Confirmation (Required)

1. User requests commit with explicit language
2. AI proposes Conventional Commit message
3. AI asks:
   "Is this acceptable?
   (yes/no/modify)"
4. AI waits for confirmation before executing

## Ambiguous Phrases - Do NOT Interpret as Commit

| Phrase | Response |
|--------|----------|
| "Save my work" | "Changes saved to files. Would you like to commit?" |
| "Save this" | Ask: commit, stage, or just edit? |
| "Create a PR" | Check if committed first, get explicit authorization |

## Never Commit

- Secrets, API keys, sensitive data
- Large binary files (use Git LFS)
- Generated files, build artifacts
- Debug code, temporary files
