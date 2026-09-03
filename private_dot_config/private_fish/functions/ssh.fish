function ssh --wraps ssh --description "ssh with safe TERM for remote hosts"
    TERM=xterm-256color command ssh $argv
end
