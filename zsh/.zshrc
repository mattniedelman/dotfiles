#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

if [[ "$OSTYPE" == darwin* ]]; then
    PATH="${HOME}/bin:/usr/local/anaconda3/bin:$PATH"
    PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
    PATH="/usr/local/Cellar/gnu-getopt/1.1.6/bin:$PATH"
fi

if [[ "$OSTYPE" == linux-gnu ]]; then
    PATH="${HOME}/bin:$PATH"
    PATH="${HOME}/miniconda3/bin:$PATH"
    PATH="/usr/local/go/bin:$PATH"
fi

# Customize to your needs...
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
wd() {
  . /Users/mattniedelman/bin/wd/wd.sh
}
source <(kubectl completion zsh)
unsetopt correct
unsetopt correct_all
setopt CLOBBER

export EDITOR=nvim
