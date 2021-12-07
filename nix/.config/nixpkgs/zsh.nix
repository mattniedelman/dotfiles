{ pkgs, lib, ... }:
let
  ohmyzsh = pkgs.fetchFromGitHub {
    owner = "ohmyzsh";
    repo = "ohmyzsh";
    rev = "7a4f4ad91e1f937b36a54703984b958abe9da4b8";
    sha256 = "1p43x3sx54h4vgbaa4iz3j1yj4d0qcnxlcq9c2z4q6j7021gjbvi";
  };

in

{
  programs.zsh =
    {
      enable = true;
      defaultKeymap = "emacs";
      enableAutosuggestions = false;
      sessionVariables = {
        EDITOR = "nvim";
      };
      shellAliases = {
        k = "kubectl";
        cdr = "cd $(git rev-parse --show-toplevel)";
        tf = "terraform";
      };
      # completionInit = ''
      #   autoload -U +X compinit
      #   autoload -U +X bashcompinit
      #   if [ $(date +'%j') != $(/usr/bin/stat -f '%Sm' -t '%j' ''${ZDOTDIR:-$HOME}/.zcompdump) ]; then
      #     compinit
      #     bashcompinit
      #   else
      #     compinit -C
      #     bashcompinit -C
      #   fi
      # '';
      enableSyntaxHighlighting = true;
      envExtra = ''
        PATH="$HOME/go/bin:$PATH"
        PATH="$HOME/.local/bin:$PATH"
        PATH="/usr/local/go/bin:$PATH"
        PATH="$HOME/bin:$PATH"
        PATH="$HOME/anaconda3/bin:$PATH"
        PATH="$HOME/miniconda3/bin:$PATH"

        DEFAULT_USER=mattniedelman

        DOCKER_HOST=ssh://matt@100.106.87.24
        RPS1=""
      '';
      initExtraFirst = ''
        skip_global_compinit=1
      '';
      initExtra = ''
        # zstyle ':completion:*' menu select
        # zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' '+l:|=* r:|=*'
        # zstyle ':completion:*' verbose yes
        # zstyle ':completion:*:descriptions' format "$fg[yellow]%B--- %d%b"
        # zstyle ':completion:*:messages' format '%d'
        # zstyle ':completion:*:warnings' format "$fg[red]No matches for:$reset_color %d"
        # zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'


        eval $(/opt/homebrew/bin/brew shellenv)

        bindkey "^[[1;5C" forward-word
        bindkey "^[[1;5D" backward-word
        bindkey "^[[3~" delete-char
        bindkey "^[[A" up-line-or-search
        bindkey "^[[B" down-line-or-search
        bindkey '^ ' autosuggest-accept

        prompt_kubeconfig() {
        if [[ -n $KUBECONFIG ]]; then
          color=red
          prompt_segment $color $PRIMARY_FG
          print -Pn " $(basename $KUBECONFIG) "
        fi
        }
        typeset -aHg AGNOSTER_PROMPT_SEGMENTS=(
            prompt_status
            prompt_context
            prompt_virtualenv
            prompt_dir
            prompt_git
            prompt_kubeconfig
            prompt_end
        )

        autoload up-line-or-beginning-search
        autoload down-line-or-beginning-search
        zle -N up-line-or-beginning-search
        zle -N down-line-or-beginning-search
        bindkey "\e[A" up-line-or-beginning-search
        bindkey "\e[B" down-line-or-beginning-search

        setopt prompt_cr
        setopt prompt_sp
        setopt extendedglob
        setopt promptsubst

        source "$HOME/bin/.ktx"
        source "$HOME/bin/.ktx-completion.sh"
        source <(kubectl completion zsh)
        source <(skaffold completion zsh)
        source <(helm completion zsh)

      '';
      plugins = [
        {
          name = "agnoster";
          file = "agnoster.zsh-theme";
          src = pkgs.fetchFromGitHub {
            owner = "agnoster";
            repo = "agnoster-zsh-theme";
            rev = "6bba672c7812a76defc3efed9b6369eeee2425dc";
            sha256 = "1p6kx63s050nyhr7y49fjqy7d54zcdrgp0jy2ykhpmps490w1afz";
          };
        }
        {
          name = "omz-clipboard";
          file = "lib/clipboard.zsh";
          src = ohmyzsh;
        }
        {
          name = "omz-completion";
          file = "lib/completion.zsh";
          src = ohmyzsh;
        }
        {
          name = "omz-directories";
          file = "lib/directories.zsh";
          src = ohmyzsh;
        }
        {
          name = "omz-termsupport";
          file = "lib/termsupport.zsh";
          src = ohmyzsh;
        }
        {
          name = "omz-key-bindings";
          file = "lib/key-bindings.zsh";
          src = ohmyzsh;
        }
        {
          name = "omz-ag";
          file = "plugins/ag/_ag";
          src = ohmyzsh;
        }
        {
          name = "omz-direnv";
          file = "plugins/direnv/direnv.plugin.zsh";
          src = ohmyzsh;
        }
        {
          name = "omz-docker";
          file = "plugins/docker/_docker";
          src = ohmyzsh;
        }
        {
          name = "omz-fzf";
          file = "plugins/fzf/fzf.plugin.zsh";
          src = ohmyzsh;
        }
        {
          name = "omz-git-auto-fetch";
          file = "plugins/git-auto-fetch/git-auto-fetch.plugin.zsh";
          src = ohmyzsh;
        }
        {
          name = "omz-wd";
          file = "plugins/wd/wd.plugin.zsh";
          src = ohmyzsh;
        }
      ];
      # {
      #   name = "robbyrussell/oh-my-zsh";
      #   tags = [ "use:lib/{clipboard,completion,directories,history,termsupport,key-bindings}.zsh" ];
      # }
      # {
      #   name = "plugins/docker";
      #   tags = [ "from:oh-my-zsh" ];
      # }
      # {
      #   name = "plugins/git";
      #   tags = [ "from:oh-my-zsh" ];
      # }
      # {
      #   name = "plugins/gradle";
      #   tags = [ "from:oh-my-zsh" ];
      # }
      # {
      # name = "plugins/wd";
      # tags = [ "from:oh-my-zsh" ];
      # }
      # {
      #   name = "lukechilds/zsh-nvm";
      # }
      # ];
      # };
    };
}
