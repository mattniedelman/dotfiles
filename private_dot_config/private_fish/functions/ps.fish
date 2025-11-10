function ps --wraps=procs --description 'Use procs in interactive mode, ps otherwise'
    if isatty stdout; and command -q procs
        command procs $argv
    else
        command ps $argv
    end
end

