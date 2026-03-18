#!/bin/bash
#
# PostToolUse:launch-process - Auto-capture knowledge from bd comments add
#
# Detects: bd comments add {BEAD_ID} "LEARNED: ..." / "DECISION: ..." /
#          "FACT: ..." / "PATTERN: ..." / "INVESTIGATION: ..."
# Writes directly to Basic Memory via `bm tool write-note`
#
# Inspired by beads-compound's memory-capture.sh
#

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only process launch-process (bash commands)
[[ "$TOOL_NAME" != "launch-process" ]] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$COMMAND" ]] && exit 0

# Must be a bd comments add command with knowledge prefix
echo "$COMMAND" | grep -qE 'bd\s+comments?\s+add\s+' || exit 0
echo "$COMMAND" | grep -qE '(INVESTIGATION:|LEARNED:|DECISION:|FACT:|PATTERN:)' || exit 0

# Extract BEAD_ID
BEAD_ID=$(echo "$COMMAND" | sed -E 's/.*bd[[:space:]]+comments?[[:space:]]+add[[:space:]]+([A-Za-z0-9._-]+)[[:space:]]+.*/\1/')
[[ -z "$BEAD_ID" || "$BEAD_ID" == "$COMMAND" ]] && exit 0

# Extract comment body
COMMENT_BODY=$(echo "$COMMAND" | sed -E 's/.*bd[[:space:]]+comments?[[:space:]]+add[[:space:]]+[A-Za-z0-9._-]+[[:space:]]+["'\'']//' | sed -E 's/["'\''][[:space:]]*$//' | head -c 2048)
[[ -z "$COMMENT_BODY" ]] && exit 0

# Detect type and extract content
TYPE="" CONTENT="" CATEGORY=""
for PREFIX in INVESTIGATION LEARNED DECISION FACT PATTERN; do
  if echo "$COMMENT_BODY" | grep -q "^${PREFIX}:"; then
    TYPE=$(echo "$PREFIX" | tr '[:upper:]' '[:lower:]')
    CONTENT=$(echo "$COMMENT_BODY" | sed "s/^${PREFIX}:[[:space:]]*//" | head -c 1024)
    case "$PREFIX" in
      LEARNED) CATEGORY="learning" ;;
      DECISION) CATEGORY="decision" ;;
      FACT) CATEGORY="fact" ;;
      PATTERN) CATEGORY="pattern" ;;
      INVESTIGATION) CATEGORY="investigation" ;;
    esac
    break
  fi
done
[[ -z "$TYPE" || -z "$CONTENT" ]] && exit 0

# Generate title
TITLE_SLUG=$(echo "$CONTENT" | head -c 50 | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//')
TITLE="${TYPE}-${TITLE_SLUG}"

# Build tags (space-separated for bm tool)
TAGS="${TYPE} beads ${BEAD_ID}"
for tag in auth oauth api database sql postgres redis cache performance \
           async concurrency test debug error config deploy docker kubernetes \
           fastapi python typescript react security; do
  echo "$CONTENT" | grep -qi "$tag" && TAGS="${TAGS} ${tag}"
done

# Build note content
NOTE_CONTENT="# ${TYPE^}: ${CONTENT:0:60}

## Context

Captured from beads comment on ${BEAD_ID}.

## Content

${CONTENT}

## Observations

- [${CATEGORY}] ${CONTENT} #${TYPE} #beads #${BEAD_ID}

## Relations

- captured-from [[beads-${BEAD_ID}]]"

# Write to Basic Memory (async, don't block)
if command -v bm &>/dev/null; then
  echo "$NOTE_CONTENT" | bm tool write-note \
    --title "$TITLE" \
    --folder "knowledge/learnings" \
    --tags "$TAGS" \
    --format json >/dev/null 2>&1 &
fi

# Notify agent (brief confirmation)
cat << EOF
{
  "hookSpecificOutput": {
    "additionalContext": "📝 Auto-captured to Basic Memory: knowledge/learnings/${TITLE}"
  }
}
EOF

