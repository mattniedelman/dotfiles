#!/bin/bash
#
# SessionStart hook: Auto-inject relevant knowledge based on beads context
#
# Queries current beads and searches Basic Memory for related knowledge.
# Uses `bm tool search-notes` to actually retrieve and inject knowledge.
#

INPUT=$(cat)

# Exit silently if bd (beads CLI) is not installed
command -v bd &>/dev/null || exit 0
command -v bm &>/dev/null || exit 0

# Get workspace from input
CWD=$(echo "$INPUT" | jq -r '.workspace_roots[0] // empty' 2>/dev/null)
[[ -z "$CWD" ]] && CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[[ -z "$CWD" ]] && exit 0

# Check if this is a beads project
[[ ! -d "$CWD/.beads" ]] && exit 0
cd "$CWD" || exit 0

# Get in-progress beads (priority) and open beads
IN_PROGRESS=$(bd list --status=in_progress --json 2>/dev/null | jq -r '.[].id' 2>/dev/null | head -3 || true)
OPEN_BEADS=$(bd list --status=open --json 2>/dev/null | jq -r '.[].id' 2>/dev/null | head -3 || true)
ALL_BEADS=$(echo -e "${IN_PROGRESS}\n${OPEN_BEADS}" | grep -v '^$' | head -5)

if [[ -z "$ALL_BEADS" ]]; then
  READY_COUNT=$(bd ready --json 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
  if [[ "$READY_COUNT" -gt 0 ]]; then
    cat << EOF
{"hookSpecificOutput":{"additionalContext":"## Beads: ${READY_COUNT} tasks ready\n\nRun \`bd ready\` to see available work.\n\n**Log knowledge with prefixes** (auto-captured to Basic Memory):\n\`bd comments add <ID> \"LEARNED: ...\"\`"}}
EOF
  fi
  exit 0
fi

# Build search terms from bead titles and IDs
SEARCH_TERMS=""
BEAD_CONTEXT=""
for BEAD_ID in $ALL_BEADS; do
  BEAD_JSON=$(bd show "$BEAD_ID" --json 2>/dev/null || true)
  TITLE=$(echo "$BEAD_JSON" | jq -r '.[0].title // empty' 2>/dev/null)
  STATUS=$(echo "$BEAD_JSON" | jq -r '.[0].status // "unknown"' 2>/dev/null)

  if [[ -n "$TITLE" ]]; then
    # Format bead for display
    SHORT_TITLE=$(echo "$TITLE" | head -c 50)
    BEAD_CONTEXT="${BEAD_CONTEXT}- **${BEAD_ID}** (${STATUS}): ${SHORT_TITLE}\n"

    # Extract keywords for search
    KEYWORDS=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | grep -oE '\b[a-z]{4,}\b' | \
      grep -vE '^(the|and|for|with|from|that|this|have|been|will|into|should|would|could|make|when|what|where)$' | head -3)
    SEARCH_TERMS="$SEARCH_TERMS $KEYWORDS"
  fi

  # Also search by bead ID tag
  SEARCH_TERMS="$SEARCH_TERMS $BEAD_ID"
done

# Add git branch keywords
BRANCH=$(git branch --show-current 2>/dev/null || true)
if [[ -n "$BRANCH" && "$BRANCH" != "main" && "$BRANCH" != "master" ]]; then
  BRANCH_KW=$(echo "$BRANCH" | tr '-_/' ' ' | grep -oE '\b[a-z]{4,}\b' | head -2)
  SEARCH_TERMS="$SEARCH_TERMS $BRANCH_KW"
fi

# Dedupe and limit search terms
SEARCH_TERMS=$(echo "$SEARCH_TERMS" | tr ' ' '\n' | sort -u | grep -v '^$' | head -6 | tr '\n' ' ' | sed 's/ *$//')

# Search Basic Memory for related knowledge
KNOWLEDGE=""
if [[ -n "$SEARCH_TERMS" ]]; then
  # Search with beads tag filter for highly relevant results
  BM_RESULTS=$(bm tool search-notes "$SEARCH_TERMS" --tag beads --page-size 5 --format json 2>/dev/null || true)

  if [[ -n "$BM_RESULTS" && "$BM_RESULTS" != "[]" && "$BM_RESULTS" != "null" ]]; then
    # Extract titles and permalinks from results
    KNOWLEDGE=$(echo "$BM_RESULTS" | jq -r '.results[]? | "- [\(.title // .permalink)](\(.permalink))"' 2>/dev/null | head -5)
  fi

  # If no beads-tagged results, do a broader search
  if [[ -z "$KNOWLEDGE" ]]; then
    BM_RESULTS=$(bm tool search-notes "$SEARCH_TERMS" --page-size 5 --format json 2>/dev/null || true)
    if [[ -n "$BM_RESULTS" && "$BM_RESULTS" != "[]" && "$BM_RESULTS" != "null" ]]; then
      KNOWLEDGE=$(echo "$BM_RESULTS" | jq -r '.results[]? | "- [\(.title // .permalink)](\(.permalink))"' 2>/dev/null | head -5)
    fi
  fi
fi

# Build context message
CONTEXT="## Active Beads\n\n${BEAD_CONTEXT}"

if [[ -n "$KNOWLEDGE" ]]; then
  CONTEXT="${CONTEXT}\n## Related Knowledge (from Basic Memory)\n\n${KNOWLEDGE}\n"
fi

CONTEXT="${CONTEXT}\n**Auto-capture**: \`bd comments add <ID> \"LEARNED|DECISION|PATTERN: ...\"\` writes to Basic Memory"

cat << EOF
{"hookSpecificOutput":{"additionalContext":"${CONTEXT}"}}
EOF

