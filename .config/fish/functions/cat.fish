function cat --wraps=bat --description 'Use glow for markdown, bat otherwise in interactive mode'
    if isatty stdout
        if command -q markless; and string match -qr '\.md$' -- $argv[-1]
            command markless --watch --wrap-width 100 --toc $argv
        else if command -q bat
            command bat --style=plain $argv
        else
            command cat $argv
        end
    else
        command cat $argv
    end
end
