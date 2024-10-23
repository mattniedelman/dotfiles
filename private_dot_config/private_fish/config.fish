
source "$HOME/.asdf/asdf.fish"
if status is-interactive
    # Commands to run in interactive sessions can go here
    fish_add_path "$HOME/bin"
    fish_add_path "$HOME/.krew/bin"
    fish_add_path "$HOME/.cargo/bin"
    fish_add_path "$HOME/.local/bin"
    fish_add_path "(asdf which rustc)/.."
    source ~/.asdf/plugins/golang/set-env.fish
    fish_add_path "$GOROOT/bin"
    fish_add_path "$GOPATH/bin"
end

set -Ux EDITOR nvim
set -Ux fish_greeting ""
set -Ux SSH_AUTH_SOCK ~/.1password/agent.sock
# set -Ux AWS_DEFAULT_PROFILE 439323037767_AI-Developer
set -Ux DIRENV_LOG_FORMAT ""
set -Ux TERM xterm-kitty
set -Ux FZF_DEFAULT_OPTS --layout=reverse --border --margin=1 --padding=1

set -Ux LC_COLLATE en_US


set --global tide_right_prompt_items status cmd_duration virtual_env kubectl time
alias cdr='cd (git rev-parse --show-toplevel)'
alias k='kubectl'
alias tf='terraform'
alias icat="kitty +kitten icat"
alias nvim=nvimvenv
alias gl='geek-life'


fzf_configure_bindings --directory=\ct
set fzf_fd_opts --no-ignore --exclude __pycache__

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
set --export --prepend PATH "/home/mattniedelman/.rd/bin"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
