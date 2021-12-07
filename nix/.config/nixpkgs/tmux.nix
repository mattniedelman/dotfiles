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
    historyLimit = 1000000;
    newSession = true;
    sensibleOnTop = true;
    extraConfig = ''
      set -g mouse on;
      bind c new-window -c "#{pane_current_path}"
      bind '"' split-window -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
    '';
  };
}
