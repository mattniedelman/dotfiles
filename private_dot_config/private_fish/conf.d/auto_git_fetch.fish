function __auto_git_fetch --on-variable PWD
    status is-command-substitution; and return

    # Only act inside a git work tree
    git rev-parse --is-inside-work-tree &>/dev/null; or return

    set -l git_dir (git rev-parse --git-dir 2>/dev/null); or return
    set -l stamp $git_dir/.last_autofetch
    set -l throttle 300  # seconds between fetches per repo

    # Throttle: skip if this repo was fetched recently
    if test -f $stamp
        set -l age (math (date +%s) - (stat -c %Y $stamp))
        test $age -lt $throttle; and return
    end
    touch $stamp

    # Fetch quietly in the background so the prompt never blocks
    fish -c "git -C '$PWD' fetch --quiet &>/dev/null" &
    disown
end
