# Zellij - Advanced Reference

## All Keybind Actions

### Pane Actions

```kdl
NewPane                             // new pane (auto direction)
NewPane "down"                      // new pane below
NewPane "right"                     // new pane right
CloseFocus                          // close focused pane
ToggleFocusFullscreen               // fullscreen current pane
ToggleFloatingPanes                 // show/hide all floating panes
TogglePaneEmbedOrFloating           // embed floating or float embedded pane
TogglePaneFrames                    // toggle pane borders
MoveFocus "left"                    // focus pane (left/right/up/down)
MoveFocusOrTab "left"               // focus pane, or prev/next tab at edge
SwitchFocus                         // cycle focus
PaneNameInput 0                     // start pane rename input
UndoRenamePane                      // cancel rename
SwitchToMode "renamepane"           // enter rename mode
```

### Tab Actions

```kdl
NewTab
CloseTab
GoToTab 1                           // 1-indexed
GoToNextTab
GoToPreviousTab
ToggleTab                           // switch to last-used tab
BreakPane                           // move pane out to new tab
BreakPaneLeft                       // move pane to tab on left
BreakPaneRight                      // move pane to tab on right
ToggleActiveSyncTab                 // sync input to all panes in tab
TabNameInput 0
UndoRenameTab
MoveTab "left"                      // reorder tab
MoveTab "right"
```

### Move / Resize Actions

```kdl
MovePane                            // cycle pane position
MovePane "left"                     // move to direction
MovePaneBackwards                   // cycle backwards
Resize "Increase"                   // increase focused direction
Resize "Decrease"
Resize "Increase left"              // directional resize
Resize "Decrease right"
```

### Scroll / Search Actions

```kdl
ScrollUp
ScrollDown
HalfPageScrollUp
HalfPageScrollDown
PageScrollUp
PageScrollDown
ScrollToBottom
EditScrollback                      // open scrollback in $EDITOR
SearchInput 0                       // begin search input
Search "down"                       // next match
Search "up"                         // previous match
SearchToggleOption "CaseSensitivity"
SearchToggleOption "WholeWord"
SearchToggleOption "Wrap"
```

### Session / Plugin Actions

```kdl
Detach
Quit
LaunchOrFocusPlugin "zellij:session-manager" {
    floating true
    move_to_focused_tab true
}
LaunchOrFocusPlugin "file:~/.config/zellij/plugins/myplugin.wasm" {
    floating true
    cwd "/path"
    my_option "value"               // arbitrary plugin config
}
```

### Mode Switching

```kdl
SwitchToMode "locked"
SwitchToMode "normal"
SwitchToMode "pane"
SwitchToMode "tab"
SwitchToMode "resize"
SwitchToMode "move"
SwitchToMode "scroll"
SwitchToMode "entersearch"
SwitchToMode "search"
SwitchToMode "session"
SwitchToMode "renametab"
SwitchToMode "renamepane"
```

## Advanced Keybinding Patterns

### Scope keywords

```kdl
keybinds clear-defaults=false {
    // Specific mode
    locked {
        bind "Ctrl g" { SwitchToMode "normal"; }
    }

    // Active in listed modes only
    shared_among "normal" "locked" {
        bind "Ctrl \\" { NewPane "right"; }
    }

    // Active in all modes except listed
    shared_except "locked" "entersearch" "renametab" "renamepane" {
        bind "Ctrl g" { SwitchToMode "locked"; }
        bind "esc"    { SwitchToMode "locked"; }
    }
}
```

### Multi-action binds

```kdl
bind "Alt s" {
    LaunchOrFocusPlugin "file:~/.config/zellij/plugins/sessionizer.wasm" {
        floating true
        move_to_focused_tab true
    }
    SwitchToMode "locked"
}
```

### clear-defaults vs incremental

```kdl
// Start from scratch — must define everything
keybinds clear-defaults=true { ... }

// Layer on top of stock keybinds (default)
keybinds clear-defaults=false { ... }
```

## Advanced Layouts

### Swap Layouts (toggle between views)

```kdl
// Panes stay the same, layout rearranges
swap_tiled_layout name="vertical" {
    pane split_direction="vertical" {
        pane
        pane
    }
}
swap_tiled_layout name="horizontal" {
    pane split_direction="horizontal" {
        pane
        pane
    }
}
```

Toggle: `Ctrl+p`, then `Space`

### Development Layout with Sidebar

```kdl
// ~/.config/zellij/layouts/project-sidebar.kdl
layout {
    pane split_direction="vertical" {
        pane size=1 borderless=true {
            plugin location="zellij:session-manager"
        }
        pane split_direction="horizontal" {
            pane command="nvim" { args "."; }
            pane split_direction="vertical" {
                pane command="lazygit"
                pane    // shell
            }
        }
    }
}
```

### Multi-Project Layout

```kdl
layout {
    tab name="frontend" {
        pane split_direction="vertical" {
            pane command="nvim" { args "frontend/"; }
            pane command="fish" { cwd "frontend"; }
        }
    }
    tab name="backend" focus=true {
        pane split_direction="vertical" {
            pane command="nvim" { args "backend/"; }
            pane command="fish" { cwd "backend"; }
        }
    }
    tab name="logs" {
        pane split_direction="horizontal" {
            pane command="fish"
            pane command="fish"
        }
    }
}
```

### Override Layout at Runtime

```bash
# Replace current tab's layout
zellij action override-layout dev

# Keep existing terminal panes, apply new structure
zellij action override-layout --retain-existing-terminal-panes dev

# Apply only to active tab
zellij action override-layout --apply-only-to-active-tab dev
```

### Remote Layouts

```bash
# Load layout from URL (prompts for confirmation for security)
zellij --layout https://example.com/layouts/myteam.kdl
```

## Plugin System

### Architecture

- Plugins are **WASM/WASI** binaries
- Run as first-class panes — can render UI and respond to state
- Officially supported in **Rust**; community support for other languages

### Declaring and loading plugins

```kdl
// config.kdl
plugins {
    // alias = location with optional config
    my-plugin location="file:~/.config/zellij/plugins/my-plugin.wasm" {
        some_option "value"
    }
    session-manager location="zellij:session-manager"
    zjstatus location="file:~/.config/zellij/plugins/zjstatus.wasm"
}

// Load at startup (background, no UI unless floated)
load_plugins {
    my-plugin
    zjstatus
}
```

### Plugin in layout

```kdl
pane borderless=true {
    plugin location="zellij:tab-bar"
}

pane floating=true {
    plugin location="file:~/.config/zellij/plugins/sessionizer.wasm" {
        root_dirs "/home/user/projects"
        session_layout "~/.config/zellij/layouts/dev.kdl"
    }
}
```

### Installing community plugins

```bash
# Download .wasm to plugin dir
curl -Lo ~/.config/zellij/plugins/zjstatus.wasm \
  https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm
```

## Full Configuration Reference

```kdl
// ~/.config/zellij/config.kdl

// Appearance
theme "nord"                    // built-in: nord, catppuccin-mocha, gruvbox-dark, ayu, etc.
pane_frames false               // hide pane borders
simplified_ui false

// Behavior
default_shell "fish"
default_layout "compact"        // layout name from ~/.config/zellij/layouts/
default_mode "locked"           // start every session in locked mode
mouse_mode true
scroll_buffer_size 100000
copy_on_select true
copy_command "xclip -selection clipboard"
on_force_close "quit"           // "quit" or "detach"
show_startup_tips false

// Session persistence
session_serialization true      // restore layout/panes after re-attach
```

### Config file locations (search order)

1. `--config-dir` CLI flag
2. `$ZELLIJ_CONFIG_DIR` env var
3. `~/.config/zellij/`
4. macOS default: `~/Library/Application Support/org.Zellij-Contributors.Zellij/`
5. System: `/etc/zellij/`

## Scripting Zellij

```bash
# Control specific session from outside
zellij --session my-session run -- my-cmd
zellij --session my-session action new-tab --layout dev
zellij --session my-session action write-chars "ls -la\n"

# Dump current layout to file
zellij action dump-layout > ~/layouts/current.kdl

# Stream active pane output to stdout
zellij subscribe

# Read-only watch another session
zellij watch my-session
```

## tmux Migration

| tmux | zellij | Notes |
|------|--------|-------|
| `tmux new -s name` | `zellij -s name` | Named session |
| `tmux attach -t name` | `zellij attach name` | Attach |
| `Ctrl+b c` | `t` → `n` | New tab (in tab mode) |
| `Ctrl+b %` | `p` → `r` | Split right |
| `Ctrl+b "` | `p` → `d` | Split down |
| `Ctrl+b [` | `s` + scroll | Scroll mode |
| `Ctrl+b d` | `o` → `d` | Detach |
| `Ctrl+b z` | `p` → `f` | Fullscreen |
| `tmux kill-session` | `zellij kill-session` | Kill |
| `tmux ls` | `zellij ls` | List |

### Key mindset differences

- **Modes vs prefix**: zellij uses modal input, not a prefix key
- **Locked mode**: `Ctrl+g` passes all keys to terminal (no prefix needed at all)
- **`default_mode "locked"`**: best ergonomics — normal terminal behavior, enter modes only when needed
- **Floating panes**: `p` → `w` — no tmux equivalent
- **KDL layouts**: zellij can fully reconstruct sessions from layout files
- **Tab sync**: `t` → `s` broadcasts input to all panes in a tab (like tmux synchronize-panes)
