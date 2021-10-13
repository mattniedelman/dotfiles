{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    ignores = [
      ".DS_Store"
    ];
    userEmail = "matt.niedelman@kaizenanalytix.com";
    userName = "Matt Niedelman";
  };
}
