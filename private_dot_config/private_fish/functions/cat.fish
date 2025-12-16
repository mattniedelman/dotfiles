function cat --wraps=bat --description 'Use bat in interactive mode, cat otherwise'
    if isatty stdout; and command -q bat
        command bat --style=plain $argv
    else
        command cat $argv
    end
end
