
source "$HOME/.asdf/asdf.fish"
if status is-interactive
    # Commands to run in interactive sessions can go here
    fish_add_path "$HOME/bin"

end

set -Ux EDITOR nvim
set -Ux fish_greeting ""

alias cdr='cd (git rev-parse --show-toplevel)'
alias k='kubectl'
alias tf='terraform'

fzf_configure_bindings --directory=\ct

