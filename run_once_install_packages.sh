#!/bin/bash

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
    yaml-language-server

dotnet tool install --global csharp-ls

pip install 'python-lsp-server[all]'

cargo install --locked taplo-cli
