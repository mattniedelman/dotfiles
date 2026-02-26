# Export BASH_ENV so non-interactive bash subshells (e.g., Augment CLI) get proper PATH
set -gx BASH_ENV "$HOME/.bash_env"
