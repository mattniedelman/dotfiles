# Determine if a completion value should have a trailing space
# This function implements smart spacing logic:
# - No space for directories and partial paths (allow further completion)
# - No space for values ending with special characters (=, :, @)
# - Space for complete arguments, commands, and discrete values
function __tv_should_add_space
    set -l value $argv[1]
    set -l line $argv[2]

    # Don't add space if the value ends with a path separator (incomplete directory)
    if string match -q "*/" "$value"
        return 1
    end

    # Don't add space if it's a directory (could be navigated into)
    if test -d "$value"
        return 1
    end

    # Don't add space if the value looks like a partial path
    # This handles cases like "src/ma" where you might want to complete to "src/main.py"
    if string match -q "*/*" "$value"
        # Check if the parent directory exists, suggesting this could be a partial path
        set -l parent_dir (string replace -r '/[^/]*$' '' "$value")
        if test -d "$parent_dir" 2>/dev/null
            return 1
        end
    end

    # Don't add space if the current token ends with certain characters that suggest continuation
    set -l current_token (commandline -ct)
    if string match -qr '[=:@]$' "$current_token"
        return 1
    end

    # Don't add space if the value looks like it might be part of a compound argument
    # e.g., "--option=value" or "key:value" patterns
    if string match -qr '^[^/]*[=:]' "$value"
        return 1
    end

    # Special case: if this looks like a file extension or partial filename, don't add space
    if string match -qr '\.[a-zA-Z0-9]*$' "$value" && not test -f "$value"
        return 1
    end

    # Special handling for kubectl and similar commands where namespaces should get spaces
    set -l tokens (string split ' ' "$line")
    if test (count $tokens) -ge 1
        set -l cmd $tokens[1]
        # For kubectl, docker, and similar commands, most completions should have spaces
        # unless they're clearly paths
        if string match -q kubectl "$cmd" || string match -q docker "$cmd"
            # These are usually discrete arguments that should have spaces
            return 0
        end
    end

    # Add space for most other cases (commands, complete arguments, namespaces, etc.)
    return 0
end

# Escape a value for safe insertion into the command line
# Only escapes if the value contains characters that need it
function __tv_escape_value
    set -l value $argv[1]

    # Only escape if value contains spaces or shell metacharacters
    if string match -qr '[ \t\'"$`!#<>|;&(){}*?\\[\\]]' -- "$value"
        string escape --no-quoted -- "$value"
    else
        printf '%s' "$value"
    end
end

# Drive tv with fish's own completions
function __tv_fish_completions
    # Text up to the cursor (best for computing completions)
    set -l line (commandline -cp)

    # For commands with tv channel triggers, use tv's smart autocomplete instead
    # This enables channels like git-diff which provide richer completions
    # But first check if there's only one completion - if so, use it directly
    if string match -qr '^git (add|restore)\b' "$line"
        set -l git_comps (complete -C "$line")
        if test (count $git_comps) -eq 1
            # Only one completion - auto-complete it directly
            set -l comp $git_comps[1]
            set -l value (string split -m1 \t -- "$comp")[1]
            set -l escaped (__tv_escape_value "$value")
            if __tv_should_add_space "$value" "$line"
                commandline -rt -- "$escaped "
            else
                commandline -rt -- "$escaped"
            end
            commandline -f repaint
            return
        end
        tv_smart_autocomplete
        return
    end

    # Ask fish to produce completions for this line.
    # 'complete -C STRING' prints matching completions for STRING.
    set -l comps (complete -C "$line")

    # Sort completions: items ending in / (directories) go to the bottom
    # This makes files and commands appear first in the tv picker
    set -l non_dir_comps
    set -l dir_comps
    for comp in $comps
        set -l value (string split -m1 \t -- "$comp")[1]
        if string match -q "*/" "$value"
            set -a dir_comps "$comp"
        else
            set -a non_dir_comps "$comp"
        end
    end
    # Recombine: non-directories first, then directories
    set comps $non_dir_comps $dir_comps

    if test (count $comps) -eq 0
        # Nothing from fish; show the normal pager
        commandline -f complete-and-search
        return
    else if test (count $comps) -eq 1
        # Only one completion available - auto-complete it directly
        set -l comp $comps[1]
        set -l value (string split -m1 \t -- "$comp")[1]

        # Escape the value for safe insertion
        set -l escaped (__tv_escape_value "$value")

        # Determine if we should add a space
        if __tv_should_add_space "$value" "$line"
            commandline -rt -- "$escaped "
        else
            commandline -rt -- "$escaped"
        end
        commandline -f repaint
        return
    end

    # Find the maximum width of completion values for columnar alignment
    set -l max_width 0
    for comp in $comps
        set -l value (string split -m1 \t -- "$comp")[1]
        set -l width (string length -- "$value")
        if test $width -gt $max_width
            set max_width $width
        end
    end

    # Format completions with aligned columns
    set -l formatted
    for comp in $comps
        set -l parts (string split -m1 \t -- "$comp")
        set -l value $parts[1]
        if test (count $parts) -gt 1
            # Has description - pad value and add description with spacing
            set -l padded (printf "%-*s" $max_width "$value")
            set -a formatted "$padded  $parts[2]"
        else
            # No description - just the value
            set -a formatted "$value"
        end
    end

    # Let tv fuzzy-filter those completions; user picks one.
    set -l picked (printf '%s\n' $formatted | tv)

    if test -n "$picked"
        # Extract the value part (before the aligned description)
        # Trim whitespace to get the actual value
        set -l value (string trim -- (string split -m1 '  ' -- "$picked")[1])

        # Escape the value for safe insertion
        set -l escaped (__tv_escape_value "$value")

        # Determine if we should add a space
        if __tv_should_add_space "$value" "$line"
            commandline -rt -- "$escaped "
        else
            commandline -rt -- "$escaped"
        end
        commandline -f repaint
    end
    # If nothing was picked (Ctrl+C), just return to prompt without fallback
end
