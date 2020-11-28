{ config, pkgs, ... }:

{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home = {
    username = "mattniedelman";
    homeDirectory = "/home/mattniedelman";
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
      wget
      unzip
      gnumake
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
    sessionVariables = {
      EDITOR = "nvim";
    };
    initExtraBeforeCompInit = ''
      source ${pkgs.zplug}/init.zsh

      ${builtins.readFile ./.zplugrc}
  '';
  };
}
