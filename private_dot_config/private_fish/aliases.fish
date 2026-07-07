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
# beads (bd): gastownhall/beads, installed via mise
# ============================================================================
# `bd` resolves via the mise shim (github:gastownhall/beads). No alias needed.
# Embedded Dolt backend. The interim beads_rust (`br`) binary is still present
# at ~/.local/bin/br, and the old Go bd at ~/.local/bin/bd-legacy-v1.0.3, but
# `bd` on $PATH is the mise-managed gastownhall build with the full command set
# (`dolt`, `prime`, `remember`, `memories` all work).
