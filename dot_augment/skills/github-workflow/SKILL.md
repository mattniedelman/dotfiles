---
name: github-workflow
description: Use when reading GitHub data - PRs, issues, CI status, releases, and search via the read-only GitHub MCP server
---

# GitHub Workflow

Use the GitHub MCP server tools (`*_github` suffix) for read operations.
Never use `web-fetch` for GitHub resources.

**Configuration:** Server runs in read-only mode.
Write operations (create PR, file issues, merge) are handled by the user
directly.

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
| GitHub read operations | `*_github` MCP tools | Read-only mode |
| Local git operations | `git_*` MCP tools | See git-workflow rules |
| Write operations | User handles directly | Not available to agent |
| `web-fetch` on GitHub | Never | Bypasses auth, returns HTML |

## Available Read Operations

### Pull Requests

| Tool | Purpose |
|------|---------|
| `list_pull_requests_github` | List PRs with filters (state, base, head) |
| `pull_request_read_github` | Get PR details, diff, files, reviews, comments |
| `search_pull_requests_github` | Search PRs with query syntax |

### Issues

| Tool | Purpose |
|------|---------|
| `list_issues_github` | List issues with filters |
| `issue_read_github` | Get issue details, comments, labels, sub-issues |
| `search_issues_github` | Search issues with query syntax |

### Repository

| Tool | Purpose |
|------|---------|
| `get_file_contents_github` | Get file or directory contents |
| `list_branches_github` | List branches |
| `list_commits_github` | List commits with filters |
| `get_commit_github` | Get commit details with diff |
| `search_code_github` | Search code across repos |
| `search_repositories_github` | Find repositories |

### Releases and Tags

| Tool | Purpose |
|------|---------|
| `list_releases_github` | List releases |
| `get_latest_release_github` | Get latest release |
| `get_release_by_tag_github` | Get release by tag |
| `list_tags_github` | List tags |
| `get_tag_github` | Get tag details |

### Users and Teams

| Tool | Purpose |
|------|---------|
| `get_me_github` | Get authenticated user info |
| `search_users_github` | Search users |
| `get_teams_github` | Get user's teams |
| `get_team_members_github` | Get team members |

## Write Operations (User-Handled)

The following are **not available** in read-only mode.
User handles directly:

- Creating/merging PRs
- Filing/updating issues
- Adding comments
- Creating releases
- Pushing files

If work is ready for PR creation, inform the user:
"Changes are ready.
Would you like to create a PR?"
