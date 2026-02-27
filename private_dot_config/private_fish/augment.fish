# ============================================================================
# Augment CLI Integration
# ============================================================================
# Enables direct slash commands from shell: /note, /todo, /tasks, etc.
# Uses abbreviations for expansion + tab completion.

# Abbreviations expand as you type (with space or enter)
abbr --add note 'auggie command note'
abbr --add todo 'auggie command todo'
abbr --add tasks 'auggie command tasks'
abbr --add enhance 'auggie command enhance'
abbr --add research 'auggie command research'
abbr --add organize 'auggie command organize'
abbr --add brainstorm 'auggie command brainstorm'

# Fallback: intercept /command syntax for those who prefer the slash
function fish_command_not_found
    if string match -q '/*' $argv[1]
        set -l cmd (string replace -r '^/' '' $argv[1])
        auggie command $cmd $argv[2..-1]
    else
        __fish_default_not_found_handler $argv
    end
end

