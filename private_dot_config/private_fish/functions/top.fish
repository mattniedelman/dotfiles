function top --wraps=btm --description 'Use bottom in interactive mode, top otherwise'
    if isatty stdout; and command -q btm
        command btm $argv
    else
        command top $argv
    end
end
