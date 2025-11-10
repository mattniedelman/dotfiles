#!/usr/bin/env bash
# KICS wrapper script for diagnosticls integration
# Formats KICS JSON output into a format that diagnosticls can parse

set -euo pipefail

# Check if KICS is installed
if ! command -v kics &> /dev/null; then
    echo "Error: KICS is not installed. Please install it first:" >&2
    echo "  brew install kics (macOS)" >&2
    echo "  or download from https://github.com/Checkmarx/kics/releases" >&2
    exit 1
fi

# Get the file path from arguments
FILE_PATH="${1:-}"

if [ -z "$FILE_PATH" ]; then
    echo "Error: No file path provided" >&2
    exit 1
fi

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File not found: $FILE_PATH" >&2
    exit 1
fi

# Create temporary directory for KICS output
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Run KICS scan
kics scan \
    --no-progress \
    --silent \
    --ci \
    --report-formats json \
    --output-path "$TEMP_DIR" \
    --output-name kics-results \
    --path "$FILE_PATH" \
    --exclude-severities trace \
    2>/dev/null || true

# Check if results file exists
RESULTS_FILE="$TEMP_DIR/kics-results.json"
if [ ! -f "$RESULTS_FILE" ]; then
    # No issues found or scan failed
    exit 0
fi

# Parse JSON and format for diagnosticls
# Format: filename:line:column: [SEVERITY] message
jq -r '
  .queries[]? |
  .files[]? as $file |
  "\($file.file_name):\($file.line // 1):1: [\(.severity)] \(.query_name): \(.description // .issue_type // "Security issue detected")"
' "$RESULTS_FILE" 2>/dev/null || exit 0

exit 0

