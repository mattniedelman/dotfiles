#!/usr/bin/env bash
# PreToolUse: Enforce git worktree placement at $REPO_ROOT/.worktrees/<name>
#
# Blocks any `git worktree add` where the destination path is not a descendant
# of $REPO_ROOT/.worktrees/.  Sibling paths, /tmp, and arbitrary locations are
# rejected before the command runs.
#
# Uses the Claude Code hook JSON protocol (same as rtk-rewrite.sh):
#   permissionDecision: "block" → rejects the tool call with a reason
#   exit 0 with no output      → pass through unchanged

set -euo pipefail

if ! command -v jq &>/dev/null; then
	exit 0
fi

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only intercept git worktree add
echo "$CMD" | grep -qE 'git[[:space:]]+worktree[[:space:]]+add' || exit 0

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[[ -n "$CWD" ]] || exit 0

REPO_ROOT=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null) || exit 0
REPO_ROOT_REAL=$(realpath "$REPO_ROOT")

# ---------------------------------------------------------------------------
# Parse the destination path from: git worktree add [<options>] <path> [<commit>]
# Strip the verb prefix, then known flags (with/without values), leaving the
# first positional token as the path.
# ---------------------------------------------------------------------------
STRIPPED=$(echo "$CMD" | sed -E 's/^.*git[[:space:]]+worktree[[:space:]]+add[[:space:]]*//')

# Boolean flags (no value)
for FLAG in --force -f --checkout --no-checkout --detach -d --orphan --no-track --guess-remote; do
	STRIPPED=$(echo "$STRIPPED" | sed -E "s/(^|[[:space:]])${FLAG//\//\\/}([[:space:]]|$)/ /g")
done

# Flags that consume the next token
for FLAG in -b -B --reason --track; do
	STRIPPED=$(echo "$STRIPPED" | sed -E "s/(^|[[:space:]])${FLAG}[[:space:]]+[^[:space:]]+/ /g")
done

WPATH=$(echo "$STRIPPED" | awk '{print $1}')
[[ -n "$WPATH" ]] || exit 0

# Resolve to absolute
if [[ "$WPATH" != /* ]]; then
	WPATH="$CWD/$WPATH"
fi
WPATH=$(realpath -m "$WPATH")

REQUIRED_PREFIX="${REPO_ROOT_REAL}/.worktrees/"

# Allow if already correct
[[ "$WPATH" == "${REQUIRED_PREFIX}"* ]] && exit 0

# Block with a clear reason
REASON="Worktree placement policy: path must be under \$REPO_ROOT/.worktrees/<branch>. Attempted: $WPATH — Required prefix: ${REQUIRED_PREFIX}. Retry with: ${REQUIRED_PREFIX}<branch-name>"

jq -n \
	--arg reason "$REASON" \
	'{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": $reason
    }
  }'
exit 2
