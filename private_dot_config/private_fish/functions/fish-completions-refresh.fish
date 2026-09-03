# Probe all mise shims for fish completions, running probes in parallel.
# Usage: fish-completions-refresh [--force] [--jobs=N]
#   --force     Re-probe even previously-failed tools
#   --jobs=N    Parallel workers (default: 8)
function fish-completions-refresh
    set -l shims_dir ~/.local/share/mise/shims
    set -l tried_dir ~/.cache/fish-completion-probe
    set -l force 0
    set -l parallel 8

    for arg in $argv
        switch $arg
            case --force
                set force 1
            case '--jobs=*'
                set parallel (string replace --regex '^--jobs=' '' $arg)
        end
    end

    test -d $shims_dir; or begin
        echo "No mise shims directory found"
        return 1
    end

    set -l to_probe
    set -l n_already 0
    set -l n_skipped 0

    for bin in (ls $shims_dir)
        if test -f ~/.config/fish/completions/$bin.fish
            set n_already (math $n_already + 1)
        else if test $force -eq 0; and test -f $tried_dir/$bin.tried
            set n_skipped (math $n_skipped + 1)
        else
            set -a to_probe $bin
        end
    end

    set -l total (count $to_probe)
    echo "Probing $total tools in parallel ($parallel workers) — $n_already have completions, $n_skipped previously failed"
    echo ""

    if test $total -eq 0
        echo "Nothing to do. Use --force to re-probe failed tools."
        return 0
    end

    set -l tmpfile (mktemp)

    printf '%s\n' $to_probe | xargs -P $parallel -n1 fish -c '
        set cmd $argv[1]
        if fish_probe_completion $cmd
            echo "  + $cmd"
        else if test -f ~/.cache/fish-completion-probe/$cmd.hint
            echo "  ? $cmd (man page hint)"
        else
            echo "  . $cmd (none)"
        end
    ' -- | tee $tmpfile

    set -l n_added (grep -cF ' + ' $tmpfile 2>/dev/null)
    test $status -ne 0; and set n_added 0
    set -l n_hints (grep -cF ' ? ' $tmpfile 2>/dev/null)
    test $status -ne 0; and set n_hints 0
    set -l n_failed (grep -cF ' . ' $tmpfile 2>/dev/null)
    test $status -ne 0; and set n_failed 0
    rm -f $tmpfile

    echo ""
    echo "Done: $n_added added, $n_hints need manual setup (see ~/.cache/fish-completion-probe/*.hint), $n_failed no completions found"
    test $force -eq 0; and test $n_failed -gt 0; and echo "Re-run with --force to retry previously-failed tools"
end
