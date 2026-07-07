function df --wraps=duf --description 'Use duf in interactive mode, df otherwise'
    if isatty stdout; and command -q duf
        command duf $argv
    else
        command df -h $argv
    end
end
