function cat --wraps=bat --description 'Use glow for markdown, bat otherwise in interactive mode'
    if isatty stdout
        if command -q glow; and string match -qr '\.md$' -- $argv[-1]
            command glow --pager $argv --width 100
        else if command -q bat
            command bat --style=plain $argv
        else
            command cat $argv
        end
    else
        command cat $argv
    end
end
