# cd to git root, preserving symlink paths in PWD.
# git rev-parse --show-toplevel returns the real path, so we substitute
# the resolved portion of PWD with the original PWD prefix to keep symlinks.
function cdr
    set -l toplevel (git rev-parse --show-toplevel 2>/dev/null)
    or return 1
    set -l real_pwd (realpath $PWD)
    set -l target (string replace $real_pwd $PWD $toplevel)
    cd $target
end
