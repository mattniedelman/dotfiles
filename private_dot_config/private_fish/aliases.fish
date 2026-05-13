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
# cdr: cd to git root (see functions/cdr.fish)

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
# beads_rust (br): replaces legacy bd (steveyegge/beads)
# ============================================================================
# `bd` is a symlink at ~/.local/bin/bd -> br (works from every shell including
# non-interactive ones and Claude Code's bash). Legacy bd binary preserved at
# ~/.local/bin/bd-legacy-v1.0.3. Commands that existed only in the old bd
# (`dolt`, `prime`, `remember`, `memories`) error loudly -- intentional.
