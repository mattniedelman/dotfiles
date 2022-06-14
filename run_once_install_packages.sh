#!/bin/bash

# LSP
npm install -g \
    @angular/language-server \
    @ansible/ansible-language-server \
    bash-language-server \
    vscode-langservers-extracted \
    cssmodules-language-server \
    dockerfile-language-server-nodejs \
    spectral \
    typescript-language-server \
    vim-language-server \
    yarn

yarn global add \
    diagnostic-languageserver \
    yaml-language-server \
    pyright

dotnet tool install --global csharp-ls

pip install \
    'python-lsp-server[all]' \
	semgrep

cargo install --locked taplo-cli

# Code formatting
pip install \
    black \
    isort

go install mvdan.cc/sh/v3/cmd/shfmt@latest

npm install -g \
    prettier \
	aws-azure-login
