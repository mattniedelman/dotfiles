#
# Executes commands at the start of an interactive session.
#

# zmodload zsh/zprof

if [[ ! -d ~/.zplug ]]; then
  git clone https://github.com/zplug/zplug ~/.zplug
  source ~/.zplug/init.zsh && zplug update --self
fi

source "${ZDOTDIR:-$HOME}/.zplugrc"

wd() {
  . /home/matt/bin/wd/wd.sh
}

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

source <(kubectl completion zsh)
source <(skaffold completion zsh)

source ktx
source ktx-completion.sh

eval "$(direnv hook zsh)"

unsetopt correct
unsetopt correct_all
setopt CLOBBER

bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"


# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

# zprof
#
