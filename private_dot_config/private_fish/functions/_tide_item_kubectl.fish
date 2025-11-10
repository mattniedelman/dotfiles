function _tide_item_kubectl
    kubectl config view --minify --output 'jsonpath={.current-context}/{..namespace}' 2>/dev/null | read -l context &&
        # Remove trailing slash or /default, then extract cluster name (everything after last slash)
        set -l display_name (string replace -r '/(|default)$' '' $context | string replace -r '.*/' '')
        _tide_print_item kubectl $tide_kubectl_icon' ' $display_name
end
