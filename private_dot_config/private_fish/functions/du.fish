function du --wraps=dust --description 'Use dust in interactive mode, du otherwise'
    if isatty stdout; and command -q dust
        command dust $argv
    else
        command du -h $argv
    end
end
