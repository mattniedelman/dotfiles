function auggie --description "Auggie CLI wrapper with default Sonnet 4.5 model"
    # Check if model is already specified in arguments
    set model_specified false
    for arg in $argv
        if string match -q -- "-m*" $arg; or string match -q -- "--model*" $arg
            set model_specified true
            break
        end
    end
    
    # If no model specified and we have arguments, add default model
    if test $model_specified = false; and test (count $argv) -gt 0
        # Add default model (sonnet4.5) to the beginning of arguments
        command auggie -m sonnet4.5 $argv
    else
        # Either no arguments or model already specified, use as-is
        command auggie $argv
    end
end