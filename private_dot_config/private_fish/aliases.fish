# ============================================================================
# Fish Shell Aliases
# ============================================================================
# Separated from config.fish for better organization

# ============================================================================
# Modern Tool Replacements
# ============================================================================
# Core replacements (cat, ls, grep, find, df, du, ps, top) are handled by
# functions in ~/.config/fish/functions/ that automatically detect TTY and
# fall back to standard tools in scripts/pipes.
#
# Additional convenience aliases for interactive use:

# eza: additional listing variants
if command -q eza
    alias lt='eza -T --group-directories-first' # tree view
    alias l='eza -lah --group-directories-first --git' # detailed all
end

# bat: plain mode for when you need it interactively
if command -q bat
    alias catp='bat --style=plain --paging=never'
end

# bottom: also replace htop
if command -q btm
    alias htop='btm'
end

# ============================================================================
# Git Aliases
# ============================================================================
# cdr: cd to git root, preserving symlink paths in PWD
# git rev-parse --show-toplevel returns the real path, so we substitute
# the resolved portion of PWD with the original PWD prefix to keep symlinks
function cdr
    set -l toplevel (git rev-parse --show-toplevel 2>/dev/null)
    or return 1
    set -l real_pwd (realpath $PWD)
    # If PWD contains a symlink, substitute the real path portion with the symlink path
    set -l target (string replace $real_pwd $PWD $toplevel)
    cd $target
end

# delta: better git diffs (configured via .gitconfig, not aliased)

# ============================================================================
# ast-grep (use global config)
# ============================================================================
alias sg='sg --config $AST_GREP_CONFIG'

# ============================================================================
# Kubernetes
# ============================================================================
# Note: k is defined as a function in functions/k.fish
# It wraps kubectl with auto-sshuttle for EKS clusters

# ============================================================================
# Terraform
# ============================================================================
alias tf='terraform'

# ============================================================================
# Kitty Terminal
# ============================================================================
alias icat="kitty +kitten icat"
