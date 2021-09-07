{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ag
    bazel-buildtools
    black
    cargo
    checkov
    clang-tools
    cmake
    fd
    font-awesome
    gawk
    gnugrep
    gnumake
    gnused
    gnutar
    htop
    hugo
    jsonnet
    jsonnet-bundler
    kubernetes-helm
    rnix-lsp
    ripgrep
    nixpkgs-fmt
    nodePackages.js-beautify
    nodePackages.prettier
    texlive.combined.scheme-small
    # openconnect
    rustc
    shfmt
    tanka
    tree
    unzip
    watch
    wget
    zellij
    zplug
  ];

  programs.bat.enable = true;
  programs.direnv.enable = true;
  programs.fzf.enable = true;
  programs.jq.enable = true;
  programs.go.enable = false;
}
