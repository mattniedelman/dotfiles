function grep --wraps=rg --description 'Use ripgrep in interactive mode, grep otherwise'
    if isatty stdout; and command -q rg
        command rg $argv
    else
        command grep --color=auto $argv
    end
end
