# Vikunja task management wrapper
function todo
    switch $argv[1]
        case check done
            vja toggle $argv[2..-1]
        case add new
            vja add $argv[2..-1]
        case ls list
            vja ls $argv[2..-1]
        case show
            vja show $argv[2..-1]
        case edit modify
            vja edit $argv[2..-1]
        case delete rm
            vja delete $argv[2..-1]
        case open
            vja open $argv[2..-1]
        case '*'
            vja $argv
    end
end
