#
# Defines environment variables.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ ( "$SHLVL" -eq 1 && ! -o LOGIN ) && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi

export SDKMAN_DIR="/home/matt/.sdkman"
[[ -s "/home/matt/.sdkman/bin/sdkman-init.sh" ]] && source "/home/matt/.sdkman/bin/sdkman-init.sh"

DEFAULT_USER="matt"
EDITOR=nvim
DISABLE_CORRECTION="true"
GOPATH="${HOME}/go"

PATH="${HOME}/bin:${PATH}"
PATH="/usr/local/go/bin:${PATH}"
PATH="${HOME}/go/bin:${PATH}"
PATH="${HOME}/miniconda3/bin:${PATH}"
PATH="/snap/bin:${PATH}"
PATH="${HOME}/.krew/bin:${PATH}"
alias k=kubectl
alias cat=bat
