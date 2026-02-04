#!/usr/bin/env bash
# PostToolUse hook: Check for Unicode lookalike characters in file changes
# Catches curly quotes, em dashes, smart quotes, and other problematic Unicode

set -euo pipefail

EVENT=$(cat)

# Extract file changes from the event
FILE_CHANGES=$(echo "$EVENT" | jq -r '.file_changes // []')
CHANGE_COUNT=$(echo "$FILE_CHANGES" | jq 'length')

if [ "$CHANGE_COUNT" -eq 0 ]; then
    exit 0
fi

# Unicode characters to detect (and their ASCII replacements)
# Using hex codes for reliable matching
ISSUES=""

for i in $(seq 0 $((CHANGE_COUNT - 1))); do
    FILE_PATH=$(echo "$FILE_CHANGES" | jq -r ".[$i].path // \"\"")
    CONTENT=$(echo "$FILE_CHANGES" | jq -r ".[$i].content // \"\"")
    
    if [ -z "$CONTENT" ]; then
        continue
    fi
    
    FILE_ISSUES=""
    
    # Check for em dash (U+2014)
    if echo "$CONTENT" | grep -q $'\xe2\x80\x94'; then
        FILE_ISSUES="${FILE_ISSUES}em dash (use - instead), "
    fi
    
    # Check for en dash (U+2013)
    if echo "$CONTENT" | grep -q $'\xe2\x80\x93'; then
        FILE_ISSUES="${FILE_ISSUES}en dash (use - instead), "
    fi
    
    # Check for left double quote (U+201C)
    if echo "$CONTENT" | grep -q $'\xe2\x80\x9c'; then
        FILE_ISSUES="${FILE_ISSUES}left curly double quote (use \" instead), "
    fi
    
    # Check for right double quote (U+201D)
    if echo "$CONTENT" | grep -q $'\xe2\x80\x9d'; then
        FILE_ISSUES="${FILE_ISSUES}right curly double quote (use \" instead), "
    fi
    
    # Check for left single quote (U+2018)
    if echo "$CONTENT" | grep -q $'\xe2\x80\x98'; then
        FILE_ISSUES="${FILE_ISSUES}left curly single quote (use ' instead), "
    fi
    
    # Check for right single quote / apostrophe (U+2019)
    if echo "$CONTENT" | grep -q $'\xe2\x80\x99'; then
        FILE_ISSUES="${FILE_ISSUES}right curly single quote (use ' instead), "
    fi
    
    # Check for ellipsis (U+2026)
    if echo "$CONTENT" | grep -q $'\xe2\x80\xa6'; then
        FILE_ISSUES="${FILE_ISSUES}ellipsis character (use ... instead), "
    fi
    
    # Check for non-breaking space (U+00A0)
    if echo "$CONTENT" | grep -q $'\xc2\xa0'; then
        FILE_ISSUES="${FILE_ISSUES}non-breaking space (use regular space), "
    fi
    
    # Check for minus sign (U+2212)
    if echo "$CONTENT" | grep -q $'\xe2\x88\x92'; then
        FILE_ISSUES="${FILE_ISSUES}minus sign (use - instead), "
    fi
    
    if [ -n "$FILE_ISSUES" ]; then
        # Remove trailing comma and space
        FILE_ISSUES="${FILE_ISSUES%, }"
        ISSUES="${ISSUES}${FILE_PATH}: ${FILE_ISSUES}\n"
    fi
done

if [ -n "$ISSUES" ]; then
    # Output warning as additionalContext
    ESCAPED_ISSUES=$(echo -e "$ISSUES" | jq -Rs '.')
    cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "ASCII WARNING: Unicode lookalike characters detected. Replace with ASCII equivalents:\n${ISSUES}See response-style-communication.md for the full list."
  }
}
EOF
fi

exit 0

