function ls --wraps=eza --description 'Use eza in interactive mode, ls otherwise'
    if isatty stdout; and command -q eza
        command eza --group-directories-first $argv
    else
        command ls --color=auto $argv
    end
end

