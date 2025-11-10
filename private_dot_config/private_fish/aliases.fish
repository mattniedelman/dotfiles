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
    alias lt='eza -T --group-directories-first'  # tree view
    alias l='eza -lah --group-directories-first --git'  # detailed all
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
alias cdr='cd (git rev-parse --show-toplevel)'

# delta: better git diffs (configured via .gitconfig, not aliased)

# ============================================================================
# Kubernetes
# ============================================================================
alias k='kubectl'

# ============================================================================
# Terraform
# ============================================================================
alias tf='terraform'

# ============================================================================
# Kitty Terminal
# ============================================================================
alias icat="kitty +kitten icat"

