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

if [[ "$OSTYPE" == darwin* ]]; then
    PATH="${HOME}/bin":/usr/local/anaconda3/bin:$PATH
    PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
fi


DEFAULT_USER="mattniedelman"
EDITOR=nvim
DISABLE_CORRECTION="true"
