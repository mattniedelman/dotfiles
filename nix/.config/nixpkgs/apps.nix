{ pkgs, lib, ... }:
let
  nodepkgs = with pkgs.nodePackages; [
    vscode-langservers-extracted
    bash-language-server
    yaml-language-server
    dockerfile-language-server-nodejs
    diagnostic-languageserver
  ];
in
{
  home.packages = with pkgs;
    [
      ag
      aws
      bazel-buildtools
      black
      cargo
      clang-tools
      cmake
      fd
      font-awesome
      gawk
      gcc
      ghostscript
      gnugrep
      gnumake
      gnused
      gnutar
      google-cloud-sdk
      gopls
      htop
      hugo
      imagemagick
      jsonnet
      jsonnet-bundler
      kubectl
      kubernetes-helm
      nixpkgs-fmt
      nodePackages.js-beautify
      nodePackages.prettier
      poetry
      poppler_utils
      pyright
      ripgrep
      rnix-lsp
      rustc
      shfmt
      skaffold
      tanka
      tesseract
      texlive.combined.scheme-small
      tree
      unzip
      terraform
      watch
      wget
      zellij
      zplug
    ] ++ nodepkgs;


  programs.bat.enable = true;
  programs.direnv.enable = true;
  programs.fzf.enable = true;
  programs.jq.enable = true;
  programs.go.enable = true;

}
