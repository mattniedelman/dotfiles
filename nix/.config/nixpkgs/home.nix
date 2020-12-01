{ config, pkgs, ... }:

{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home = {
    username = "matt";
    homeDirectory = "/home/matt";
    stateVersion = "21.03";
    language = {
      base = "en_US.UTF-8";
      ctype = "en_US.UTF-8";
    };
    sessionVariables = {
      LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
    };
    packages = with pkgs; [
      htop
      tree
      gawk
      wget
      unzip
      gnumake
      powerline
      powerline-fonts
      glibcLocales
      zplug
      zsh
    ];
  };


  programs.git = {
    enable = true;
    userName  = "mattniedelman";
    userEmail = "mattniedelman@gmail.com";
    extraConfig = {
      core.editor = "nvim";
      core.sshCommand = "/usr/bin/ssh";
    };
  };

  programs.neovim = {
    enable = true;
    withNodeJs = true;
    plugins = with pkgs.vimPlugins; [

      LanguageClient-neovim
      fzf-vim
      golden-ratio
      {
        plugin = goyo-vim;
        config = "let g:goyo_height='100%'";
      }
      gv-vim
      limelight-vim
      {
        plugin = limelight-vim;
        config = ''
          nmap <Leader>l <Plug>(Limelight)
          xmap <Leader>l <Plug>(Limelight)
          '';
        }
      neovim-sensible
      {
        plugin = rainbow;
        config = "let g:rainbow_active = 1";
      }
      smartpairs-vim
      syntastic
      {
        plugin = syntastic;
        config = ''
          set statusline+=%#warningmsg#
          set statusline+=%{SyntasticStatuslineFlag()}
          set statusline+=%*

          let g:syntastic_always_populate_loc_list = 1
          let g:syntastic_auto_loc_list = 1
          let g:syntastic_check_on_open = 1
          let g:syntastic_check_on_wq = 0
          '';
        }
      {
        plugin = vim-airline;
        config = ''
          let g:airline#extensions#tabline#enabled = 1
          let g:airline_powerline_fonts = 1
          let g:airline#extensions#tabline#formatter = 'unique_tail'
          '';
        }
      vim-airline-themes
      {
        plugin = vim-better-whitespace;
        config = ''
          let g:better_whitespace_enabled = 1
          let g:strip_whitespace_on_save = 1
          let g:strip_whitespace_confirm = 0
          '';
        }
      vim-codefmt
      {
        plugin = vim-colors-solarized;
        config = ''
          set background=dark
          set termguicolors
          colorscheme solarized
          let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
          let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
          '';
        }
      {
        plugin = vim-codefmt;
        config = ''
          augroup autoformat_settings
            autocmd FileType bzl AutoFormatBuffer buildifier
            autocmd FileType c,cpp,proto,javascript,arduino AutoFormatBuffer clang-format
            autocmd FileType dart AutoFormatBuffer dartfmt
            autocmd FileType go AutoFormatBuffer gofmt
            autocmd FileType gn AutoFormatBuffer gn
            autocmd FileType html,css,sass,scss,less,json AutoFormatBuffer js-beautify
            autocmd FileType java AutoFormatBuffer google-java-format
            autocmd FileType python AutoFormatBuffer yapf
            " Alternative: autocmd FileType python AutoFormatBuffer autopep8
            autocmd FileType rust AutoFormatBuffer rustfmt
            autocmd FileType vue AutoFormatBuffer prettier
          augroup END
          '';
        }
      vim-commentary
      vim-fugitive
      vim-gitgutter
      vim-numbertoggle
      vim-pandoc
      vim-pandoc-syntax
      vim-polyglot
    ];
    extraConfig = ''
      noremap Q <nop>
      noremap q <nop>

      imap fd <ESC>
      vmap fd <ESC>

      map <C-a> <ESC>^
      imap <C-a> <ESC>^i

      map <C-e> <ESC>$
      imap <C-e> <ESC>$a

      nmap <S-Enter> O<ESC>
      nmap <CR> o<ESC>

      set nocompatible
      set clipboard+=unnamedplus
    '';
    extraPackages = [
      pkgs.bazel-buildtools
      pkgs.clang-tools
      pkgs.black
      pkgs.shfmt
      pkgs.nodePackages.prettier
      pkgs.nodePackages.js-beautify
    ];
  };
  programs.bat = {
    enable = true;
  };

  programs.direnv = {
    enable = true;
  };

  programs.fzf = {
    enable = true;
  };

  programs.go = {
    enable = true;
  };

  programs.jq = {
    enable = true;
  };

  programs.zsh = {
    enable = true;
    defaultKeymap = "emacs";
    enableAutosuggestions = true;
    sessionVariables = {
      EDITOR = "nvim";
      LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
    };
    shellAliases = {
      k = "kubectl";
    };
    envExtra = ''
      PATH="$HOME/go/bin:$PATH"
      if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/nix.sh"; fi
    '';
    initExtra = ''
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word
      bindkey "^[[3~" delete-char
      bindkey "^[[A" history-beginning-search-backward
      bindkey "^[[B" history-beginning-search-forward

      source "$HOME/bin/.ktx"
      source "$HOME/bin/.ktx-completion.sh"

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
    '';
    zplug = {
      enable = true;
      plugins = [
        {
          name = "robbyrussell/oh-my-zsh";
          tags = ["use:lib/{clipboard,completion,directories,history,termsupport,key-bindings}.zsh"];
        }
        {
          name = "agnoster/agnoster-zsh-theme";
          tags = ["as:theme"];
        }
        {
          name = "plugins/docker";
          tags = ["from:oh-my-zsh"];
        }
        {
          name = "plugins/git";
          tags = ["from:oh-my-zsh"];
        }
        {
          name = "plugins/gradle";
          tags = ["from:oh-my-zsh"];
        }
        {
          name = "plugins/helm";
          tags = ["from:oh-my-zsh"];
        }
        {
          name = "plugins/kubectl";
          tags = ["from:oh-my-zsh"];
        }
        {
          name = "plugins/wd";
          tags = ["from:oh-my-zsh"];
        }
      ];
    };
  };
}
