# ============================================================================
# Fish Shell Abbreviations
# ============================================================================
# Abbreviations expand immediately when you press Space or Enter, showing
# the full command before execution. This helps with learning commands and
# creates better shell history.

# ============================================================================
# Claude Code
# ============================================================================
abbr -a cc 'nono run --profile dev --allow . --allow-unix-socket "$SSH_AUTH_SOCK" -- claude'

# ============================================================================
# Chezmoi - Dotfile Management
# ============================================================================
abbr -a che chezmoi

# ============================================================================
# Kubernetes - Context and Namespace Switching
# ============================================================================
abbr -a kx kubectx
abbr -a kns kubectl ns
