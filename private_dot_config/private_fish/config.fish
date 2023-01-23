
source "$HOME/.asdf/asdf.fish"
if status is-interactive
    # Commands to run in interactive sessions can go here
    fish_add_path "$HOME/bin"
    fish_add_path "$GOPATH/bin"
end

set -Ux EDITOR nvim
set -Ux fish_greeting ""
set -Ux SSH_AUTH_SOCK ~/.1password/agent.sock
set -Ux AWS_DEFAULT_PROFILE 439323037767_AI-Developer
set -Ux DIRENV_LOG_FORMAT ""
set -Ux TERM xterm-color

alias cdr='cd (git rev-parse --show-toplevel)'
alias k='kubectl'
alias tf='terraform'
alias icat="kitty +kitten icat"
alias nvim=nvimvenv

fzf_configure_bindings --directory=\ct

