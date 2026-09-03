function git --wraps git
    if test (count $argv) -gt 0; and test "$argv[1]" = push; and contains -- --force $argv; or contains -- -f $argv
        set -l new_argv
        for arg in $argv
            if test "$arg" = "--force" -o "$arg" = "-f"
                set -a new_argv --force-with-lease
            else
                set -a new_argv $arg
            end
        end
        command git $new_argv
    else
        command git $argv
    end
end
