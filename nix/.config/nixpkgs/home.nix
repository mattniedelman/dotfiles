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
    };
  };

  programs.neovim = {
    enable = true;
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
    sessionVariables = {
      EDITOR = "nvim";
    };
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
