# Clear direnv state immediately to prevent mise warnings in subshells
# (inherited from parent fish/direnv environment)
unset DIRENV_DIFF DIRENV_WATCHES 2>/dev/null

# Editor used by CLI
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"

eval "$(mise activate bash)"
# mise exports `cd` as a function wrapping __zsh_like_cd, but does not export
# __zsh_like_cd itself. Non-interactive bash inherits the broken wrapper from
# the parent shell, causing silent cd failures. Unset it to restore builtin cd.
unset -f cd popd pushd 2>/dev/null

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init bash)"; fi
