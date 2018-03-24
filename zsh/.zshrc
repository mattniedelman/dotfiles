source ~/.config/antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle pip
antigen bundle wd
antigen bundle docker
antigen bundle git-flow
antigen bundle httpie
antigen bundle python
antigen bundle taskwarrior
antigen bundle kubectl

# Misc plugins from awesome-zsh
antigen bundle chrissicool/zsh-256color
antigen bundle zpm-zsh/autoenv
antigen bundle mafredri/zsh-async

antigen bundle seletskiy/zsh-fuzzy-search-and-edit
bindkey '^F' fuzzy-search-and-edit


antigen bundle zlsun/solarized-man
antigen bundle jreese/zsh-titles


# Load the theme.
antigen theme agnoster

# Antigen plugin updater
antigen bundle unixorn/autoupdate-antigen.zshplugin

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting

antigen bundle zsh-users/zsh-autosuggestions

# Tell Antigen that you're done.
antigen apply

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Weird fix for antigen completions bug
source $HOME/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/kubectl/kubectl.plugin.zsh
