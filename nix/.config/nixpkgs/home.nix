{ config, pkgs, ... }:
{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  # programs.home-manager.path = "/Users/mattniedelman/git/home-manager";

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "mattniedelman";
  home.homeDirectory = "/Users/mattniedelman";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.05";

  imports = [
    ./apps.nix
    ./nvim.nix
    ./zsh.nix
    ./git.nix
  ];
}
