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
set -gx TERM xterm
set -gx DIRENV_LOG_FORMAT ""
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

    # Auto-start zellij (skip if already inside zellij or in VSCode/IDE terminals)
    if command -q zellij; and not set -q ZELLIJ; and not set -q VSCODE_INJECTION
        exec zellij
    end

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

# --- Gas Town Integration ---
set -gx GT_TOWN_ROOT ~/gt

# Generate completions if not present
if not test -f ~/.config/fish/completions/gt.fish
    gt completion fish >~/.config/fish/completions/gt.fish 2>/dev/null
end
# --- End Gas Town ---

# Auggie Swarm shortcuts
alias sn='swarm-new'
alias sr='swarm-resume'
set -gx GITHUB_TOKEN (gh auth token)

# --- Beads Integration ---
# Centralized beads workflow: all issues route to ~/.beads-planning
# Auto-labels issues with repo name, falls back to central repo when not in a project
function bd --wraps bd --description "Beads wrapper with auto-labeling and central fallback"
    # Handle create command: auto-add repo label
    if test "$argv[1]" = create
        set -l repo_name (basename (git rev-parse --show-toplevel 2>/dev/null) 2>/dev/null)
        if test -n "$repo_name"
            command bd create $argv[2..-1] -l "repo:$repo_name"
            return $status
        end
    end

    # If in a directory with .beads, use it (routing will handle destination)
    if test -d .beads
        command bd $argv
    else
        # Fallback to central beads for commands outside of projects
        BEADS_DIR=~/.beads-planning/.beads command bd $argv
    end
end
# --- End Beads Integration ---

# stringer → beads bridge function
function stringer-import --description "Import stringer signals into beads"
    # Parse arguments
    set -l dry_run false
    set -l max_issues ""
    set -l collectors ""
    set -l repo_path "."
    set -l extra_labels ""

    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case --dry-run -n
                set dry_run true
            case --max-issues -m
                set i (math $i + 1)
                set max_issues $argv[$i]
            case --collectors -c
                set i (math $i + 1)
                set collectors $argv[$i]
            case --labels -l
                set i (math $i + 1)
                set extra_labels $argv[$i]
            case --help -h
                echo "Usage: stringer-import [OPTIONS] [REPO_PATH]"
                echo ""
                echo "Scan a repository with stringer and import signals into beads."
                echo ""
                echo "Options:"
                echo "  -n, --dry-run         Preview without importing"
                echo "  -m, --max-issues N    Limit number of issues"
                echo "  -c, --collectors X    Comma-separated collectors (e.g., todos,gitlog)"
                echo "  -l, --labels X        Extra labels to add (comma-separated)"
                echo "  -h, --help            Show this help"
                echo ""
                echo "Examples:"
                echo "  stringer-import                    # Scan current dir, import all"
                echo "  stringer-import --dry-run          # Preview what would be imported"
                echo "  stringer-import -c todos -m 10     # Only TODOs, max 10 issues"
                echo "  stringer-import ~/projects/myapp   # Scan specific repo"
                return 0
            case '*'
                # Assume it's the repo path if it exists
                if test -d $argv[$i]
                    set repo_path $argv[$i]
                else
                    echo "Unknown option or invalid path: $argv[$i]" >&2
                    return 1
                end
        end
        set i (math $i + 1)
    end

    # Get repo name for labeling
    set -l repo_name (basename (realpath $repo_path))

    # Build extra labels string for jq
    set -l extra_labels_jq ""
    if test -n "$extra_labels"
        set extra_labels_jq ", $extra_labels"
    end

    # Create temp files
    set -l jsonl_file (mktemp /tmp/stringer-import.XXXXXX.jsonl)
    set -l md_file (mktemp /tmp/stringer-import.XXXXXX.md)

    echo "Scanning $repo_path with stringer..." >&2

    # Run stringer and capture JSONL (stderr goes to terminal)
    set -l stringer_cmd "stringer scan $repo_path -f beads"
    if test -n "$max_issues"
        set stringer_cmd "$stringer_cmd --max-issues $max_issues"
    end
    if test -n "$collectors"
        set stringer_cmd "$stringer_cmd -c $collectors"
    end

    eval $stringer_cmd >$jsonl_file
    set -l stringer_status $status

    if test $stringer_status -ne 0
        echo "stringer failed with exit code $stringer_status" >&2
        rm -f $jsonl_file $md_file
        return $stringer_status
    end

    # Count signals
    set -l signal_count (wc -l < $jsonl_file | string trim)

    if test "$signal_count" -eq 0
        echo "No signals found." >&2
        rm -f $jsonl_file $md_file
        return 0
    end

    echo "Found $signal_count signal(s)." >&2

    # Convert JSONL to beads markdown format using jq
    cat $jsonl_file | jq -r --arg repo "$repo_name" --arg extra "$extra_labels_jq" '
        "## " + .title + "\n\n" +
        .description + "\n\nStringer ID: " + .id + "\n\n" +
        "### Priority\n" + (.priority | tostring) + "\n\n" +
        "### Type\n" + .type + "\n\n" +
        "### Labels\nrepo:" + $repo + ", " + (.labels | join(", ")) + $extra + "\n"
    ' >$md_file

    if test "$dry_run" = true
        echo "" >&2
        echo "=== DRY RUN - Preview of issues to create ===" >&2
        echo "" >&2
        cat $md_file
        echo "" >&2
        echo "Run without --dry-run to import these issues." >&2
        rm -f $jsonl_file $md_file
        return 0
    end

    # Import into beads
    echo "Importing into beads..." >&2
    BEADS_DIR=~/.beads-planning/.beads command bd create -f $md_file --json
    set -l result $status

    rm -f $jsonl_file $md_file
    return $result
end
