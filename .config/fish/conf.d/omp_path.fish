function __update_display_path --on-variable PWD --description "Update OMP_PATH for oh-my-posh prompt"
    # Collapse middle dirs to first-letters only once the full path exceeds this.
    set -l max_len 50
    set -l git_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -n "$git_root"
        set -l repo_name (basename $git_root)
        # --show-prefix returns path from repo root to cwd, with trailing slash (empty at root)
        set -l prefix (git rev-parse --show-prefix 2>/dev/null)
        set -l rel_path (string replace -r '/$' "" $prefix)

        # Build the full, unabbreviated path first.
        set -l full $repo_name
        if test -n "$rel_path"
            set full "$repo_name/$rel_path"
        end

        # Show it verbatim when it fits; otherwise collapse middle dirs.
        if test (string length "$full") -le $max_len
            set -gx OMP_PATH $full
        else
            set -l parts (string split "/" $rel_path)
            set -l count (count $parts)
            if test $count -le 1
                set -gx OMP_PATH $full
            else
                set -l result $repo_name
                for i in (seq 1 (math $count - 1))
                    set result "$result/"(string sub -l 1 $parts[$i])
                end
                set -gx OMP_PATH "$result/$parts[$count]"
            end
        end
    else
        set -gx OMP_PATH (prompt_pwd)
    end
end

__update_display_path
