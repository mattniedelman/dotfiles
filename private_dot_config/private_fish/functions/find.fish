function find --wraps=fd --description 'Use fd in interactive mode, find otherwise'
    if isatty stdout; and command -q fd
        command fd $argv
    else
        command find $argv
    end
end

