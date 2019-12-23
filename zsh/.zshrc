#
# Executes commands at the start of an interactive session.
#
if [[ ! -d ~/.zplug ]]; then
  git clone https://github.com/zplug/zplug ~/.zplug
  source ~/.zplug/init.zsh && zplug update --self
fi

source "${ZDOTDIR:-$HOME}/.zplugrc"


if [[ "$OSTYPE" == darwin* ]]; then
    PATH="${HOME}/bin:/usr/local/anaconda3/bin:$PATH"
    PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
    PATH="/usr/local/Cellar/gnu-getopt/1.1.6/bin:$PATH"
    PATH="${HOME}/go/bin:$PATH"
    PATH="${HOME}/.linkerd2/bin:$PATH"
fi

if [[ "$OSTYPE" == linux-gnu ]]; then
    PATH=".:${HOME}/bin:$PATH"
    PATH="${HOME}/miniconda3/bin:$PATH"
    PATH="/usr/local/go/bin:$PATH"
    PATH="/snap/bin:$PATH"
    PATH="${HOME}/.linkerd2/bin:$PATH"
    PATH="$PATH:/usr/local/kubebuilder/bin"
    GOPATH="${HOME}/go"
    PATH="${GOPATH}/bin:$PATH"

    SKAFFOLD_DEFAULT_REPO="localhost:32000"
    SKAFFOLD_INSECURE_REGISTRY="localhost:32000"
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source <(kubectl completion zsh)
source <(skaffold completion zsh)
eval "$(direnv hook zsh)"
unsetopt correct
unsetopt correct_all
setopt CLOBBER
alias k=kubectl
alias cat=bat
export EDITOR=nvim

wd() {
  . /home/matt/bin/wd/wd.sh
}
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word


[ -s "/home/matt/.jabba/jabba.sh" ] && source "/home/matt/.jabba/jabba.sh"
