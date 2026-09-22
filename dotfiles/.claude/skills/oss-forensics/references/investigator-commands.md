# Phase 2 Investigator Command Blocks

Verbatim collection commands for each Phase 2 specialist investigator. The
SKILL.md body holds each investigator's role boundary and evidence-to-collect
list; this file holds the runnable command blocks they execute. Each
investigator stays in its single data source -- do not mix sources.

Deeper recipes live alongside these:

- Git history recovery (force-pushed commits, dangling objects, deleted files)
  -- see [recovery-techniques.md](./recovery-techniques.md).
- BigQuery query templates, the 12 event types, CDX API parameters, and Wayback
  recovery -- see [github-archive-guide.md](./github-archive-guide.md).

---

## Investigator 1: Local Git Investigator

Query the LOCAL GIT REPOSITORY ONLY. Do not call any external APIs.

```bash
# Clone repository
git clone https://github.com/OWNER/REPO.git target_repo && cd target_repo

# Full commit log with stats
git log --all --full-history --stat --format="%H|%ae|%an|%ai|%s" > ../git_log.txt

# Detect force-push evidence (orphaned/dangling commits)
git fsck --lost-found --unreachable 2>&1 | grep commit > ../dangling_commits.txt

# Check reflog for rewritten history
git reflog --all > ../reflog.txt

# List ALL branches including deleted remote refs
git branch -a -v > ../branches.txt

# Find suspicious large binary additions
git log --all --diff-filter=A --name-only --format="%H %ai" -- "*.so" "*.dll" "*.exe" "*.bin" > ../binary_additions.txt

# Check for GPG signature anomalies
git log --show-signature --format="%H %ai %aN" > ../signature_check.txt 2>&1
```

See [recovery-techniques.md](./recovery-techniques.md) for accessing
force-pushed commits in depth.

---

## Investigator 2: GitHub API Investigator

Query the GITHUB REST API ONLY. Do not run git commands locally.

```bash
# Commits (paginated)
curl -s "https://api.github.com/repos/OWNER/REPO/commits?per_page=100" > api_commits.json

# Pull Requests including closed/deleted
curl -s "https://api.github.com/repos/OWNER/REPO/pulls?state=all&per_page=100" > api_prs.json

# Issues
curl -s "https://api.github.com/repos/OWNER/REPO/issues?state=all&per_page=100" > api_issues.json

# Contributors and collaborator changes
curl -s "https://api.github.com/repos/OWNER/REPO/contributors" > api_contributors.json

# Repository events (last 300)
curl -s "https://api.github.com/repos/OWNER/REPO/events?per_page=100" > api_events.json

# Check specific suspicious commit SHA details
curl -s "https://api.github.com/repos/OWNER/REPO/git/commits/SHA" > commit_detail.json

# Releases
curl -s "https://api.github.com/repos/OWNER/REPO/releases?per_page=100" > api_releases.json

# Check if a specific commit exists (force-pushed commits may 404 on commits/ but succeed on git/commits/)
curl -s "https://api.github.com/repos/OWNER/REPO/commits/SHA" | jq .sha
```

See [evidence-types.md](./evidence-types.md) for GH event types.

---

## Investigator 3: Wayback Machine Investigator

Query the WAYBACK MACHINE CDX API ONLY. Do not use the GitHub API.

```bash
# Search for archived snapshots of the repo main page
curl -s "https://web.archive.org/cdx/search/cdx?url=github.com/OWNER/REPO&output=json&limit=100&from=YYYYMMDD&to=YYYYMMDD" > wayback_main.json

# Search for a specific deleted issue
curl -s "https://web.archive.org/cdx/search/cdx?url=github.com/OWNER/REPO/issues/NUM&output=json&limit=50" > wayback_issue_NUM.json

# Search for a specific deleted PR
curl -s "https://web.archive.org/cdx/search/cdx?url=github.com/OWNER/REPO/pull/NUM&output=json&limit=50" > wayback_pr_NUM.json

# Fetch the best snapshot of a page
# Use the Wayback Machine URL: https://web.archive.org/web/TIMESTAMP/ORIGINAL_URL
# Example: https://web.archive.org/web/20240101000000*/github.com/OWNER/REPO

# Advanced: Search for deleted releases/tags
curl -s "https://web.archive.org/cdx/search/cdx?url=github.com/OWNER/REPO/releases/tag/*&output=json" > wayback_tags.json

# Advanced: Search for historical wiki changes
curl -s "https://web.archive.org/cdx/search/cdx?url=github.com/OWNER/REPO/wiki/*&output=json" > wayback_wiki.json
```

See [github-archive-guide.md](./github-archive-guide.md) for CDX API
parameters.

---

## Investigator 4: GH Archive / BigQuery Investigator

Query GITHUB ARCHIVE via BIGQUERY ONLY. This is a tamper-proof record of all
public GitHub events.

Prerequisites: Google Cloud credentials with BigQuery access
(`gcloud auth application-default login`). If unavailable, skip this
investigator and note it in the report.

Cost Optimization Rules (MANDATORY):

1. ALWAYS run a `--dry_run` before every query to estimate cost.
2. Use `_TABLE_SUFFIX` to filter by date range and minimize scanned data.
3. Only SELECT the columns you need.
4. Add a LIMIT unless aggregating.

```bash
# Template: safe BigQuery query for PushEvents to OWNER/REPO
bq query --use_legacy_sql=false --dry_run "
SELECT created_at, actor.login, payload.commits, payload.before, payload.head,
       payload.size, payload.distinct_size
FROM \`githubarchive.month.*\`
WHERE _TABLE_SUFFIX BETWEEN 'YYYYMM' AND 'YYYYMM'
  AND type = 'PushEvent'
  AND repo.name = 'OWNER/REPO'
LIMIT 1000
"
# If cost is acceptable, re-run without --dry_run

# Detect force-pushes: zero-distinct_size PushEvents mean commits were force-erased
# payload.distinct_size = 0 AND payload.size > 0 -> force push indicator

# Check for deleted branch events
bq query --use_legacy_sql=false "
SELECT created_at, actor.login, payload.ref, payload.ref_type
FROM \`githubarchive.month.*\`
WHERE _TABLE_SUFFIX BETWEEN 'YYYYMM' AND 'YYYYMM'
  AND type = 'DeleteEvent'
  AND repo.name = 'OWNER/REPO'
LIMIT 200
"
```

See [github-archive-guide.md](./github-archive-guide.md) for all 12 event types
and query patterns.

---

## Investigator 5: IOC Enrichment Investigator

Enrich EXISTING IOCs from Phase 1 using passive public sources ONLY. Do not
execute any code from the target repository.

- For each commit SHA: attempt recovery via direct GitHub URL
  (`github.com/OWNER/REPO/commit/SHA.patch`).
- For each domain/IP: check passive DNS, WHOIS records (via `web_extract` on
  public WHOIS services).
- For each package name: check npm/PyPI for matching malicious package reports.
- For each actor username: check GitHub profile, contribution history, account
  age.
- Recover force-pushed commits using 3 methods (see
  [recovery-techniques.md](./recovery-techniques.md)).
