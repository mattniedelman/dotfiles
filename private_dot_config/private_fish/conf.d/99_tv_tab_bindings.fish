# ============================================================================
# Television Tab Completion Bindings
# ============================================================================
# Loaded last (99_ prefix) to ensure it overrides any conflicting bindings
# from plugins or other configurations.

if status is-interactive
    # Bind Tab key to use television for fuzzy completion
    bind --erase --user tab
    bind --user tab __tv_fish_completions
end

