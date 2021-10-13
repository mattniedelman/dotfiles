{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      nord
      continuum
      tmux-fzf
      extrakto
    ];
    disableConfirmationPrompt = true;
    historyLimit = 10000;
    newSession = true;
    sensibleOnTop = true;
    extraConfig = ''
      set -g mouse on;
    '';
  };
}
