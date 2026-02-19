---
name: github-workflow
description: Use when performing GitHub API operations - PRs, issues, CI status, releases, and search via the github-api tool
---

# GitHub Workflow

Use the `github-api` tool for all GitHub operations.
Never use `web-fetch` for GitHub resources.

## When to Use

Use this skill when:

- Creating, reviewing, or merging pull requests
- Working with GitHub issues
- Checking CI/CD status
- Managing releases
- Searching GitHub (code, issues, PRs, commits)
- Any interaction with github.com resources

## Tool Selection

| Operation | Tool | Notes |
|-----------|------|-------|
| GitHub API operations | `github-api` | Always first choice |
| Local git operations | `git_*` MCP tools | See git-workflow rules |
| `gh` CLI | `launch-process` | Fallback only |
| `web-fetch` on GitHub | ❌ Never | Bypasses auth, returns HTML |

## Common API Operations

### Pull Requests

```text
# List PRs
GET /repos/{owner}/{repo}/pulls
  - state: open|closed|all
  - head: user:branch (filter by branch)

# Get PR details
GET /repos/{owner}/{repo}/pulls/{number}

# Create PR (REQUIRES EXPLICIT PERMISSION)
POST /repos/{owner}/{repo}/pulls
  - title, body, head, base required

# Get PR files
GET /repos/{owner}/{repo}/pulls/{number}/files

# Merge PR (REQUIRES EXPLICIT PERMISSION)
PUT /repos/{owner}/{repo}/pulls/{number}/merge
```

### Issues

```text
# List issues
GET /repos/{owner}/{repo}/issues
  - filter: assigned|created|mentioned|subscribed|all
  - state: open|closed|all
  - labels: comma-separated

# List user's issues across repos
GET /issues
  - filter parameter required

# Create/update issue
POST /repos/{owner}/{repo}/issues
PATCH /repos/{owner}/{repo}/issues/{number}
```

### CI/CD Status

```text
# Check runs (detailed)
GET /repos/{owner}/{repo}/commits/{sha}/check-runs

# Commit status (covers more CIs)
GET /repos/{owner}/{repo}/commits/{sha}/status

# Workflow runs
GET /repos/{owner}/{repo}/actions/runs
GET /repos/{owner}/{repo}/actions/runs/{run_id}
```

### Search

```text
# Search issues/PRs
GET /search/issues
  - q: is:pr is:issue author:@me state:open repo:owner/repo

# Search code
GET /search/code
  - q: search terms

# Search commits
GET /search/commits
  - q: author:{username} committer:{username}
```

### Releases

```text
GET /repos/{owner}/{repo}/releases
GET /repos/{owner}/{repo}/releases/{id}
POST /repos/{owner}/{repo}/releases  (REQUIRES PERMISSION)
```

## When to Use gh CLI

Only as fallback when:

- `github-api` tool cannot accomplish the task
- Interactive operations needed
- User explicitly requests CLI

Example fallback:

```bash
# Only if github-api insufficient
gh pr create --title "feat: add feature" --body "Description"
```

## Benefits of github-api Tool

- **Authentication**:
  Automatic, proper GitHub auth
- **Structured data**:
  JSON/YAML responses (not HTML)
- **Rate limiting**:
  Handled appropriately
- **Filtering**:
  Powerful query parameters
- **Completeness**:
  Access to all GitHub API endpoints

## Authorization

See `authorization-policies.md` for operations requiring explicit permission:

- Creating/merging PRs
- Pushing to remote
- Creating releases
- Modifying issue state
