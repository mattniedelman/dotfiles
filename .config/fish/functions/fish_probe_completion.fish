# Try common completion generation patterns for a binary.
# Usage: fish_probe_completion <cmd>
# On success: writes ~/.config/fish/completions/<cmd>.fish
# On failure: writes ~/.cache/fish-completion-probe/<cmd>.tried (sentinel)
# Returns 0 on success, 1 if no pattern worked.
function fish_probe_completion
    test (count $argv) -ge 1; or return 1
    set -l cmd $argv[1]
    set -l output_file ~/.config/fish/completions/$cmd.fish
    set -l tried_dir ~/.cache/fish-completion-probe
    set -l sentinel $tried_dir/$cmd.tried

    # Ensure mise shims are in PATH — this function runs in non-interactive subshells
    # where mise activate hasn't run yet.
    set -l _mise_shims ~/.local/share/mise/shims
    if test -d $_mise_shims; and not contains $_mise_shims $PATH
        set -gx PATH $_mise_shims $PATH
    end

    command -q $cmd; or return 1

    # Tools that don't use standard completion subcommands — skip to avoid hangs
    set -l blocklist aws aws_completer python python3 pip pip3 idle3 idle java javac node npm npx bun \
        cargo rustc rustup gcc make cmake swift swiftc eza

    if contains -- $cmd $blocklist
        mkdir -p $tried_dir
        touch $sentinel
        return 1
    end

    # Quick check: does --help mention shell completions at all?
    set -l help_text (timeout 5 $cmd --help 2>&1)
    if not string match -qi -- '*complet*' $help_text
        # No mention — check man page for fish-specific completion hints
        set -l man_hints (timeout 2 man $cmd 2>/dev/null | col -b | grep -i 'fish' | grep -i 'complet')
        mkdir -p $tried_dir
        if test -n "$man_hints"
            printf '%s\n' $man_hints >$tried_dir/$cmd.hint
        end
        touch $sentinel
        return 1
    end

    # --help mentions completions — try known generation patterns
    for pattern in \
        "completion fish" \
        "completions fish" \
        "completion -s fish" \
        "completion --shell fish" \
        "completions --shell fish" \
        "generate-shell-completion fish" \
        "gen-completion fish" \
        "gen-completions --shell fish" \
        "setup --generate-completion fish" \
        "--completion fish" \
        "--completions fish"

        set -l result (timeout 5 $cmd (string split ' ' -- $pattern) 2>/dev/null)
        if string match -q -- '*complete -c*' $result
            printf '%s\n' $result >$output_file
            return 0
        end
    end

    # Help mentions completion but no pattern worked — save hint
    set -l hints (printf '%s\n' $help_text | grep -i 'complet')
    mkdir -p $tried_dir
    if test -n "$hints"
        printf '%s\n' $hints >$tried_dir/$cmd.hint
    end
    touch $sentinel
    return 1
end
