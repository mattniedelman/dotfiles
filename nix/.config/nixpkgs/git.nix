{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    ignores = [
      ".DS_Store"
    ];
    userEmail = "matt@gradientts.com";
    userName = "Matt Niedelman";
  };
}
