# ============================================================================
# Fish Shell Configuration
# ============================================================================
# Refactored for performance, best practices, and maintainability
# See: https://fishshell.com/docs/current/

# ============================================================================
# Environment Variables (applies to all shells)
# ============================================================================
set -gx EDITOR nvim
set -gx SUDO_EDITOR ~/.local/bin/sudoedit-nvim
set -gx DIRENV_LOG_FORMAT ""
set -gx VIRTUAL_ENV_DISABLE_PROMPT true
set -gx LC_COLLATE C
set -gx RIPGREP_CONFIG_PATH ~/.ripgreprc
set -gx AST_GREP_CONFIG /home/mattniedelman/.config/ast-grep/sgconfig.yml

# AWS SSO defaults for aws-sso-util
set -gx AWS_DEFAULT_SSO_START_URL https://fairwarning.awsapps.com/start
set -gx AWS_DEFAULT_SSO_REGION us-east-2

# Note, this is for a local instance of obsidian
set -gx OBSIDIAN_REST_API_KEY f5d4c30b08affc018b35b77440b57087aba42c76200ae08e3bff4608d5493311

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
# Note: ~/.cargo/bin is omitted here -- mise manages rust and adds it via RUSTUP_TOOLCHAIN
for p in $HOME/bin $HOME/.krew/bin $HOME/.local/bin $HOME/.kubescape/bin
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
    # Fetch secrets before exec zellij so they're inherited by all panes/splits
    if not set -q AWS_BEARER_TOKEN_BEDROCK
        set -gx AWS_BEARER_TOKEN_BEDROCK (op read "op://imprivata/bedrock-dev/credential")
    end

    # Auto-start zellij in Ghostty only
    if set -q GHOSTTY_RESOURCES_DIR; and not set -q ZELLIJ; and command -q zellij
        exec zellij
    end

    # Suppress greeting
    set -g fish_greeting ""

    # ========================================================================
    # Tool Initialization
    # ========================================================================

    # Mise (development environment manager)
    command -q mise; and mise activate fish | source

    # Oh My Posh prompt
    command -q oh-my-posh; and oh-my-posh init fish --config ~/.config/ohmyposh/claude.json | source

    # Atuin (shell history sync)
    # --disable-up-arrow: Fish 4.x removed `bind -k` syntax that atuin uses for up-arrow
    command -q atuin; and atuin init fish --disable-up-arrow | source

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
        # Up arrow binding for atuin (Fish 4.x syntax - no -k flag)
        bind up _atuin_bind_up
        bind \eOA _atuin_bind_up # Up arrow escape sequence (some terminals)
        bind \e\[A _atuin_bind_up # Up arrow escape sequence (other terminals)
        bind -M insert up _atuin_bind_up 2>/dev/null
        bind -M insert \eOA _atuin_bind_up 2>/dev/null
        bind -M insert \e\[A _atuin_bind_up 2>/dev/null
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

# Added by ToolHive UI - do not modify this block
fish_add_path -g $HOME/.toolhive/bin
# End ToolHive UI

# Vikunja task management aliases
function todo
    switch $argv[1]
        case check done
            vja toggle $argv[2..-1]
        case add new
            vja add $argv[2..-1]
        case ls list
            vja ls $argv[2..-1]
        case show
            vja show $argv[2..-1]
        case edit modify
            vja edit $argv[2..-1]
        case delete rm
            vja delete $argv[2..-1]
        case open
            vja open $argv[2..-1]
        case '*'
            vja $argv
    end
end

# Beads - use systemd-managed shared Dolt server, never auto-start
set -gx BEADS_DOLT_AUTO_START 0

# --- Gas Town Integration ---
set -gx GT_TOWN_ROOT ~/gt

# Generate completions if not present
if not test -f ~/.config/fish/completions/gt.fish
    gt completion fish >~/.config/fish/completions/gt.fish 2>/dev/null
end
# --- End Gas Town ---
#

# lean-ctx shell hook -- transparent CLI compression (90+ patterns)
set -g _lean_ctx_cmds git npm pnpm yarn cargo docker docker-compose kubectl gh pip pip3 ruff go golangci-lint eslint prettier tsc ls find grep curl wget

function _lc
    if set -q LEAN_CTX_DISABLED; or not isatty stdout
        command $argv
        return
    end
    '/home/mattniedelman/.local/share/mise/shims/lean-ctx' -c $argv
    set -l _lc_rc $status
    if test $_lc_rc -eq 127 -o $_lc_rc -eq 126
        command $argv
    else
        return $_lc_rc
    end
end

function lean-ctx-on
    for _lc_cmd in $_lean_ctx_cmds
        alias $_lc_cmd '_lc '$_lc_cmd
    end
    alias k '_lc kubectl'
    set -gx LEAN_CTX_ENABLED 1
    echo 'lean-ctx: ON'
end

function lean-ctx-off
    for _lc_cmd in $_lean_ctx_cmds
        functions --erase $_lc_cmd 2>/dev/null
        true
    end
    functions --erase k 2>/dev/null
    true
    set -e LEAN_CTX_ENABLED
    echo 'lean-ctx: OFF'
end

function lean-ctx-raw
    set -lx LEAN_CTX_RAW 1
    command $argv
end

function lean-ctx-status
    if set -q LEAN_CTX_DISABLED
        echo 'lean-ctx: DISABLED (LEAN_CTX_DISABLED is set)'
    else if set -q LEAN_CTX_ENABLED
        echo 'lean-ctx: ON'
    else
        echo 'lean-ctx: OFF'
    end
end

if not set -q LEAN_CTX_ACTIVE; and not set -q LEAN_CTX_DISABLED; and test (set -q LEAN_CTX_ENABLED; and echo $LEAN_CTX_ENABLED; or echo 1) != 0
    if command -q lean-ctx
        lean-ctx-on
    end
end
# lean-ctx shell hook -- end

# Added by git-ai installer on Fri Apr 10 11:33:12 AM CDT 2026
fish_add_path -g "/home/mattniedelman/.git-ai/bin"
