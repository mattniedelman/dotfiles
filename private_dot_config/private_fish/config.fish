# ============================================================================
# Fish Shell Configuration
# ============================================================================
# Refactored for performance, best practices, and maintainability
# See: https://fishshell.com/docs/current/

# ============================================================================
# Environment Variables (applies to all shells)
# ============================================================================
set -gx EDITOR nvim
set -gx TERM xterm
set -gx DIRENV_LOG_FORMAT ""
set -gx LC_COLLATE C
set -gx RIPGREP_CONFIG_PATH ~/.ripgreprc
set -gx AST_GREP_CONFIG /home/mattniedelman/.config/ast-grep/sgconfig.yml

# SSH Agent - prefer 1Password, fallback to system agent
if test -S ~/.1password/agent.sock
    set -gx SSH_AUTH_SOCK ~/.1password/agent.sock
else if not set -q SSH_AUTH_SOCK
    echo "Warning: No SSH agent found" >&2
end

# ============================================================================
# PATH Setup (applies to all shells)
# ============================================================================
# Collect all paths to add, filtering out non-existent directories
set -l valid_paths

# Standard user paths
for p in $HOME/bin $HOME/.krew/bin $HOME/.cargo/bin $HOME/.local/bin $HOME/.kubescape/bin
    test -d $p; and set -a valid_paths $p
end

# Go paths (set by mise) - check they're not empty and exist
for p in $GOROOT/bin $GOPATH/bin $GOBIN
    test -n "$p"; and test -d "$p"; and set -a valid_paths $p
end

# Add all valid paths in a single call for better performance
test (count $valid_paths) -gt 0; and fish_add_path --path $valid_paths

# ============================================================================
# Interactive Session Setup
# ============================================================================
if status is-interactive
    # Suppress greeting
    set -g fish_greeting ""

    # Tide prompt customization
    set -g tide_right_prompt_items status cmd_duration python kubectl time

    # ========================================================================
    # Tool Initialization
    # ========================================================================

    # Mise (development environment manager)
    command -q mise; and mise activate fish | source

    # Atuin (shell history sync)
    command -q atuin; and atuin init fish | source

    # TV (version manager)
    command -q tv; and tv init fish | source

    # Direnv (directory-specific environment variables)
    command -q direnv; and direnv hook fish | source

    # ========================================================================
    # Key Bindings
    # ========================================================================
    # Override TV's Ctrl+R binding to use Atuin instead
    if command -q atuin
        bind \cr _atuin_search
        bind -M insert \cr _atuin_search 2>/dev/null
    end

    # Load Additional Configuration
    # ========================================================================

    # Aliases (separated for better organization)
    test -f ~/.config/fish/aliases.fish; and source ~/.config/fish/aliases.fish

    # Abbreviations (built-in Fish feature)
    test -f ~/.config/fish/abbreviations.fish; and source ~/.config/fish/abbreviations.fish

    # Augment CLI slash commands (/note, /todo, /tasks, etc.)
    test -f ~/.config/fish/augment.fish; and source ~/.config/fish/augment.fish

    # Machine-specific settings (not version controlled)
    test -f ~/.config/fish/local.fish; and source ~/.config/fish/local.fish
end
