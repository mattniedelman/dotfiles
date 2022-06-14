if status is-interactive
    source "$HOME/.asdf/asdf.fish"
    # Commands to run in interactive sessions can go here

end

set EDITOR nvim

alias cdr='cd $(git rev-parse --show-toplevel)'
alias k='kubectl'
alias tf='terraform'

