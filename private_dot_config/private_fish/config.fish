if status is-interactive
    # Commands to run in interactive sessions can go here
    fish_add_path "$HOME/bin"
    fish_add_path "$HOME/.krew/bin"
    fish_add_path "$HOME/.cargo/bin"
    fish_add_path "$HOME/.local/bin"
    fish_add_path "$HOME/.kubescape/bin"
    # fish_add_path "(asdf which rustc)/.."
    # source ~/.asdf/plugins/golang/set-env.fish
    fish_add_path "$GOROOT/bin"
    fish_add_path "$GOPATH/bin"
    fish_add_path "$GOBIN"
    set sponge_purge_only_on_exit true
    tv init fish | source
    atuin init fish | source
end

set -Ux EDITOR nvim
set -Ux fish_greeting ""
set -Ux SSH_AUTH_SOCK ~/.1password/agent.sock
set -Ux DIRENV_LOG_FORMAT ""
set -Ux TERM xterm

set -Ux UV_CACHE_DIR /mnt/2b20906f-1847-4c8e-94e4-b841290bddc3/.cache/uv
set -Ux UV_KEYRING_PROVIDER subprocess
set -Ux UV_INDEX_PRIVATE_REGISTRY_USERNAME aws

set --global tide_right_prompt_items status cmd_duration python kubectl time
alias cdr='cd (git rev-parse --show-toplevel)'
alias k='kubectl'
alias tf='terraform'
alias icat="kitty +kitten icat"
alias nvim=nvimvenv

fzf_configure_bindings --directory=\ct
set fzf_fd_opts --no-ignore --exclude __pycache__

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
set --export --prepend PATH "/home/mattniedelman/.rd/bin"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

/home/mattniedelman/.local/bin/mise activate fish | source
