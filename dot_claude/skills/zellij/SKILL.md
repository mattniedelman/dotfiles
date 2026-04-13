---
name: zellij
description: Use when working with zellij terminal multiplexer - session management, panes, tabs, layouts, keybindings, plugins, and CLI control
---

# Zellij Terminal Workspace

Terminal multiplexer and workspace manager.
Alternative to tmux with better defaults and UI.

## When to Use

- Managing terminal sessions, panes, and tabs
- Creating reproducible workspace layouts
- Configuring keybindings, themes, and plugins
- Running commands in new panes from scripts
- Scripting cross-session actions

## Quick Start

```bash
# Install
cargo install --locked zellij     # compile from source
cargo binstall zellij             # precompiled binary (faster)
mise use -g cargo:zellij          # via mise

# Start session
zellij
zellij -s my-session              # named session
zellij --layout dev               # with layout

# Attach
zellij attach my-session
zellij attach -c my-session       # create if not exists
zellij a my-session               # alias
```

## Modes

Zellij is modal. The **default** mode is configurable (`default_mode` in config).
Press a mode-entry key to enter a mode, then act; press `Esc`/`Enter` or mode key again to return.

| Mode | Default Entry | Purpose |
|------|--------------|---------|
| **Normal** | (transitional) | Mode-switching hub |
| **Locked** | `Ctrl+g` | Pass all keys to terminal (recommended as default) |
| **Pane** | `p` | Manage panes |
| **Tab** | `t` | Manage tabs |
| **Resize** | `r` | Resize panes |
| **Move** | `m` | Move panes |
| **Scroll** | `s` | Scroll / search buffer |
| **Session** | `o` | Session manager |

> **Tip:** Set `default_mode "locked"` so keystrokes go to the terminal by default.
> Enter other modes only when needed.

### Pane mode actions

| Key (default) | Action |
|---------------|--------|
| `n` | New pane |
| `d` | New pane down |
| `r` | New pane right |
| `x` | Close pane |
| `f` | Toggle fullscreen |
| `w` | Toggle floating panes |
| `e` | Toggle embed/float current pane |
| `c` | Rename pane |
| `h/j/k/l` | Move focus |
| `Tab` | Cycle focus |
| `Space` | Next swap layout |

### Tab mode actions

| Key (default) | Action |
|---------------|--------|
| `n` | New tab |
| `x` | Close tab |
| `r` | Rename tab |
| `h/l` | Prev / next tab |
| `1-9` | Go to tab N |
| `b` | Break pane to new tab |
| `[` / `]` | Break pane to left / right tab |
| `s` | Toggle sync mode (broadcast input to all panes) |

### Scroll mode actions

| Key (default) | Action |
|---------------|--------|
| `j/k` | Scroll down / up |
| `d/u` | Half-page down / up |
| `Ctrl+f/b` | Page down / up |
| `f` | Enter search |
| `e` | Edit scrollback in `$EDITOR` |

### Session mode actions

| Key (default) | Action |
|---------------|--------|
| `d` | Detach |
| `w` | Open session manager |
| `p` | Open plugin manager |
| `c` | Open configuration UI |

## CLI Control

```bash
# Panes
zellij run -- htop                          # command in new pane
zellij run -f -- htop                       # floating pane
zellij run -d down -- my-cmd                # specify direction
zellij edit ./file.rs                       # open in $EDITOR pane
zellij action new-pane -d right
zellij action close-pane
zellij action toggle-fullscreen
zellij action toggle-floating-panes
zellij action rename-pane "my pane"

# Tabs
zellij action new-tab
zellij action new-tab -l dev                # with layout
zellij action go-to-tab 2
zellij action rename-tab "servers"
zellij action close-tab
zellij action break-pane                    # move pane to new tab

# Session
zellij action dump-layout > layout.kdl
zellij list-sessions
zellij ls
zellij kill-session my-session
zellij kill-all-sessions

# Plugins
zellij plugin -- https://example.com/plugin.wasm
zellij action launch-or-focus-plugin my-plugin

# Observe (read-only / streaming)
zellij watch my-session                     # watch session output
zellij subscribe                            # stream active pane to stdout

# Shell completions
zellij setup --generate-completion fish
zellij setup --generate-completion bash
zellij setup --generate-completion zsh
```

### Aliases (from completions)

```bash
zr   # zellij run --
zrf  # zellij run -f --   (floating)
ze   # zellij edit
```

### Target a specific session from outside

```bash
zellij --session my-session run -- my-cmd
zellij --session my-session action new-tab
zellij --session my-session action write-chars "ls -la"
```

## Configuration

Config file: `~/.config/zellij/config.kdl`
Also read from: `$ZELLIJ_CONFIG_DIR`, `--config-dir` flag
Config is hot-reloaded — most changes apply without restart.

```bash
# Generate default config
zellij setup --dump-config > ~/.config/zellij/config.kdl
```

### Core settings

```kdl
// config.kdl
theme "nord"
default_shell "fish"
default_mode "locked"           // start in locked mode
default_layout "project-sidebar"
pane_frames false               // cleaner look without borders
mouse_mode true
scroll_buffer_size 100000
copy_on_select true
copy_command "xclip -selection clipboard"
on_force_close "quit"           // or "detach"
show_startup_tips false
session_serialization true      // restore last session on startup
```

### Keybindings

```kdl
keybinds clear-defaults=true {          // clear-defaults=false keeps stock binds
    locked {
        bind "Ctrl g" { SwitchToMode "normal"; }
    }
    shared_among "normal" "locked" {    // active in both modes
        bind "Ctrl \\" { NewPane "right"; }
        bind "Ctrl -"  { NewPane "down"; }
        bind "Alt t"   { NewTab; }
        bind "Alt f"   { ToggleFloatingPanes; }
        bind "Alt 1"   { GoToTab 1; }
        bind "Alt i"   { MoveTab "left"; }
        bind "Alt o"   { MoveTab "right"; }
    }
    shared_except "locked" "entersearch" "renametab" "renamepane" {
        bind "Ctrl g" { SwitchToMode "locked"; }
        bind "esc"    { SwitchToMode "locked"; }
    }
    // Ctrl+hjkl focus (exclude text-entry modes to keep Ctrl+h as backspace)
    shared_except "entersearch" "renametab" "renamepane" {
        bind "Ctrl h" { MoveFocus "left"; }
        bind "Ctrl j" { MoveFocus "down"; }
        bind "Ctrl k" { MoveFocus "up"; }
        bind "Ctrl l" { MoveFocus "right"; }
    }
}
```

**Keybind scope keywords:**

| Keyword | Meaning |
|---------|---------|
| `shared_among "a" "b"` | Active only in modes a and b |
| `shared_except "a" "b"` | Active in all modes except a and b |

### Plugins

```kdl
// Declare plugins with aliases
plugins {
    zjstatus location="file:~/.config/zellij/plugins/zjstatus.wasm"
    session-manager location="zellij:session-manager"   // built-in
    configuration  location="zellij:configuration"      // built-in
    plugin-manager location="zellij:plugin-manager"     // built-in
}

// Auto-load background plugins at startup
load_plugins {
    zjstatus
}
```

**Launch a plugin from a keybind:**

```kdl
bind "Alt s" {
    LaunchOrFocusPlugin "file:~/.config/zellij/plugins/zellij-sessionizer.wasm" {
        floating true
        move_to_focused_tab true
        cwd "/"
    }
}
```

## Layouts (KDL format)

Layout files live in `~/.config/zellij/layouts/` and can be referenced by name.

```kdl
// ~/.config/zellij/layouts/dev.kdl
layout {
    pane size=1 borderless=true {
        plugin location="tab-bar"
    }
    pane split_direction="vertical" {
        pane command="nvim" { args "."; }
        pane split_direction="horizontal" size="40%" {
            pane command="lazygit"
            pane                                    // empty shell
        }
    }
    pane size=2 borderless=true {
        plugin location="status-bar"
    }
}
```

**Use a layout:**

```bash
zellij --layout dev
zellij --layout ~/.config/zellij/layouts/dev.kdl
zellij action new-tab -l dev
zellij action override-layout dev                  # replace current layout
```

**Multi-tab layout:**

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
}
```

**Plugin pane in layout:**

```kdl
pane floating=true {
    plugin location="zellij:session-manager"
}
```

## Session Management

```bash
zellij list-sessions         # or: zellij ls
zellij attach <name>         # or: zellij a <name>
zellij attach -c <name>      # create if missing
zellij kill-session <name>
zellij kill-all-sessions
zellij action detach         # detach from inside session
```

## Built-in Plugins

| Name | Location | Purpose |
|------|----------|---------|
| tab-bar | `zellij:tab-bar` | Tab bar UI |
| status-bar | `zellij:status-bar` | Status bar UI |
| session-manager | `zellij:session-manager` | Session switcher |
| plugin-manager | `zellij:plugin-manager` | Browse/manage plugins |
| configuration | `zellij:configuration` | Live config UI |
| filepicker | `zellij:filepicker` | File picker |
| welcome-screen | `zellij:welcome-screen` | Welcome splash |

## Notable Community Plugins

| Plugin | Purpose |
|--------|---------|
| zjstatus | Customizable status bar replacement |
| zellij-sessionizer | Fuzzy-find sessions/projects (like tmux-sessionizer) |
| zellij-pane-tracker | Track/restore pane state |
| zellij-attention | Visual notifications for panes needing attention |

Install community plugins: download `.wasm` to `~/.config/zellij/plugins/`

## See Also

- `REFERENCE.md` for advanced layouts, swap layouts, tmux migration, keybind actions
- <https://zellij.dev/documentation>
