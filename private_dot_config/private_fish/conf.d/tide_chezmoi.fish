# Tide chezmoi item configuration
# This sets up the chezmoi status indicator in your Tide prompt

# Set default icon and color for chezmoi item
set -g tide_chezmoi_icon '📝'
set -g tide_chezmoi_color yellow

# Add chezmoi to the right prompt items (after your existing items)
# Your current items: status cmd_duration python kubectl time
# We'll add chezmoi before time
if not contains chezmoi $tide_right_prompt_items
    # Find the position of 'time' and insert before it
    set -l time_index (contains -i time $tide_right_prompt_items)
    if test -n "$time_index"
        # Insert chezmoi before time
        set -l before (seq 1 (math $time_index - 1))
        set -l after (seq $time_index (count $tide_right_prompt_items))
        set -g tide_right_prompt_items $tide_right_prompt_items[$before] chezmoi $tide_right_prompt_items[$after]
    else
        # If time not found, just append
        set -g tide_right_prompt_items $tide_right_prompt_items chezmoi
    end
end
