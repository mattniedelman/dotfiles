# Query the running basic-memory MCP server via streamable-http.
# Thin wrapper around ~/.claude/bin/bm-rpc that pretty-prints results.
#
# Usage:
#   bmq tools                      # list tool names
#   bmq tools --raw                # full tools/list response
#   bmq call <tool> [json-args]    # call a tool
#   bmq raw <method> [json-params] # arbitrary JSON-RPC method
#
# Examples:
#   bmq call search_notes '{"query":"rtk"}'
#   bmq call read_note '{"identifier":"main/foo"}'
#   bmq raw prompts/list
function bmq --description 'Query basic-memory MCP server'
    set -l rpc ~/.claude/bin/bm-rpc

    if test (count $argv) -eq 0
        echo "Usage: bmq tools|call <tool> <json>|raw <method> [json]" >&2
        return 2
    end

    set -l cmd $argv[1]
    set -e argv[1]

    switch $cmd
        case tools
            if contains -- --raw $argv
                $rpc raw tools/list '{}' | jq .
            else
                $rpc tools
            end
        case call
            if test (count $argv) -lt 1
                echo "bmq call: need <tool> [json-args]" >&2
                return 2
            end
            set -l tool $argv[1]
            set -l args '{}'
            if test (count $argv) -ge 2
                set args $argv[2]
            end
            $rpc call $tool $args | jq .
        case raw
            if test (count $argv) -lt 1
                echo "bmq raw: need <method> [json-params]" >&2
                return 2
            end
            set -l method $argv[1]
            set -l params '{}'
            if test (count $argv) -ge 2
                set params $argv[2]
            end
            $rpc raw $method $params | jq .
        case '*'
            echo "bmq: unknown subcommand '$cmd' (expected: tools|call|raw)" >&2
            return 2
    end
end
