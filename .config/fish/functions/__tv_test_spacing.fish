# Test function to verify smart spacing logic
function __tv_test_spacing
    echo "Testing smart spacing logic for TV completions:"
    echo

    # Test cases that should NOT get spaces
    set -l no_space_cases \
        src/ \
        config/ \
        src/main \
        "~/.config" \
        /usr/local \
        "file.txt" \
        "--option=" \
        "key:" \
        "user@"

    echo "Cases that should NOT get trailing spaces:"
    for case in $no_space_cases
        if __tv_should_add_space "$case" "ls $case"
            echo "  ❌ $case (incorrectly wants space)"
        else
            echo "  ✅ $case (correctly no space)"
        end
    end

    echo
    echo "Cases that SHOULD get trailing spaces:"

    # Test cases that should get spaces
    set -l space_cases \
        namespace-name \
        pod-name \
        command \
        --verbose \
        argument

    for case in $space_cases
        if __tv_should_add_space "$case" "kubectl get pods -n $case"
            echo "  ✅ $case (correctly gets space)"
        else
            echo "  ❌ $case (incorrectly no space)"
        end
    end
end
