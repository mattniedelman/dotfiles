#
# Executes commands at the start of an interactive session.
#

# zmodload zsh/zprof

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
    PATH="${PATH}:/home/matt/.linkerd2/bin"
    PATH="${PATH}:${HOME}/.nvm/versions/node/v13.7.0/bin/"

    SKAFFOLD_DEFAULT_REPO="localhost:32000"
    SKAFFOLD_INSECURE_REGISTRY="localhost:32000"
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source <(kubectl completion zsh)
source <(skaffold completion zsh)

source ktx
source ktx-completion.sh

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


# [ -s "/home/matt/.jabba/jabba.sh" ] && source "/home/matt/.jabba/jabba.sh"
wd() {
  . /home/matt/bin/wd/wd.sh
}
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/home/matt/.sdkman"
[[ -s "/home/matt/.sdkman/bin/sdkman-init.sh" ]] && source "/home/matt/.sdkman/bin/sdkman-init.sh"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"


# zprof
