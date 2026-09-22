---
name: github-workflow
description: Use when interacting with GitHub - PRs, issues, CI status, releases, search, and write operations via the GitHub MCP server
---

# GitHub Workflow

Use the GitHub API tool for all GitHub operations.
Never use `web-fetch` for GitHub resources.

**Configuration:** Server has read-write capabilities.
Read operations are auto-approved; write operations prompt for user approval.

## When to Use

Use this skill when:

- Listing or viewing pull requests
- Reading GitHub issues
- Checking CI/CD status
- Viewing releases
- Searching GitHub (code, issues, PRs, commits, users, repos)

## Tool Selection

| Operation | Tool | Notes |
|-----------|------|-------|
| GitHub read operations | GitHub API tool | Auto-approved |
| GitHub write operations | GitHub API tool | Requires user approval |
| Local git operations | git MCP tools | See git-workflow rules |
| `web-fetch` on GitHub | Never | Bypasses auth, returns HTML |

## Available Read Operations

### Pull Requests

| Operation | Purpose |
|-----------|---------|
| List PRs | List PRs with filters (state, base, head) |
| Read PR | Get PR details, diff, files, reviews, comments |
| Search PRs | Search PRs with query syntax |

### Issues

| Operation | Purpose |
|-----------|---------|
| List issues | List issues with filters |
| Read issue | Get issue details, comments, labels, sub-issues |
| Search issues | Search issues with query syntax |

### Repository

| Operation | Purpose |
|-----------|---------|
| Get file contents | Get file or directory contents |
| List branches | List branches |
| List commits | List commits with filters |
| Get commit | Get commit details with diff |
| Search code | Search code across repos |
| Search repositories | Find repositories |

### Releases and Tags

| Operation | Purpose |
|-----------|---------|
| List releases | List releases |
| Get latest release | Get latest release |
| Get release by tag | Get release by tag |
| List tags | List tags |
| Get tag | Get tag details |

### Users and Teams

| Operation | Purpose |
|-----------|---------|
| Get me | Get authenticated user info |
| Search users | Search users |
| Get teams | Get user's teams |
| Get team members | Get team members |

## Write Operations (Approval Required)

The following require user approval when invoked:

- Creating/merging PRs
- Filing/updating issues
- Adding comments
- Creating releases
- Pushing files

When ready to perform a write operation, the tool permission system will prompt
for approval automatically.
