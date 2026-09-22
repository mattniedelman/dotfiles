function top --wraps=btop --description 'Use btop in interactive mode, top otherwise'
    if isatty stdout; and command -q btop
        command btop $argv
    else
        command top $argv
    end
end
