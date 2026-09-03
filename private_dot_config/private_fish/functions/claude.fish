function claude --wraps claude --description 'Claude Code with Serena system prompt override'
    command claude --system-prompt "$(serena prompts print-cc-system-prompt-override)" $argv
end
