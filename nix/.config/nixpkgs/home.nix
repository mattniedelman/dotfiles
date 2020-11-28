{ config, pkgs, ... }:

{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home = {
    username = "mattniedelman";
    homeDirectory = "/home/mattniedelman";
    stateVersion = "21.03";
    sessionVariables = {
      LANG = "en_US.UTF-8";
      LANGUAGE = "en_US.UTF-8";
    };
    packages = with pkgs; [
      htop
      tree
      wget
      unzip
      gnumake
      powerline-fonts
      glibcLocales
      zplug
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
    zplug = {
      enable = true;
    };
    initExtraBeforeCompInit = ''
      #!/bin/env zsh
      source ${pkgs.zplug}/init.zsh
      ${builtins.readFile ./.zplugrc}
  '';
  };
}
