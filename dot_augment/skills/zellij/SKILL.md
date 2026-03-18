---
name: zellij
description: Use when working with zellij terminal multiplexer - session management, panes, tabs, layouts, keybindings, and CLI control
---

# Zellij Terminal Workspace

Terminal multiplexer and workspace manager.
Alternative to tmux with better defaults and UI.

## When to Use

- Managing terminal sessions, panes, and tabs
- Creating reproducible workspace layouts
- Running commands in new panes from scripts
- Configuring keybindings and themes

## Quick Start

```bash
# Install
cargo install zellij # or: mise use -g cargo:zellij

# Start new session
zellij
zellij -s my-session # Named session
zellij --layout dev  # With layout

# Attach to existing
zellij attach my-session
zellij attach -c my-session # Create if not exists
```

## Default Keybindings (Modal)

Zellij uses modes.
Press the mode key, then the action key.

| Mode | Enter With | Purpose |
|------|------------|---------|
| **Normal** | `Esc` | Default mode |
| **Locked** | `Ctrl+g` | Pass all keys to terminal |
| **Pane** | `Ctrl+p` | Manage panes |
| **Tab** | `Ctrl+t` | Manage tabs |
| **Resize** | `Ctrl+n` | Resize panes |
| **Move** | `Ctrl+h` | Move panes |
| **Scroll** | `Ctrl+s` | Scroll/search |
| **Session** | `Ctrl+o` | Session manager |

### Common Actions (in mode)

**Pane mode (`Ctrl+p`):**

| Key | Action |
|-----|--------|
| `n` | New pane |
| `d` | New pane down |
| `r` | New pane right |
| `x` | Close pane |
| `f` | Toggle fullscreen |
| `w` | Toggle floating |
| `h/j/k/l` | Move focus |

**Tab mode (`Ctrl+t`):**

| Key | Action |
|-----|--------|
| `n` | New tab |
| `x` | Close tab |
| `r` | Rename tab |
| `h/l` | Go to prev/next tab |
| `1-9` | Go to tab by number |

**Quick actions (Normal mode):**

| Key | Action |
|-----|--------|
| `Alt+n` | New pane |
| `Alt+h/j/k/l` | Move focus |
| `Alt+[/]` | Prev/next tab |
| `Alt++/-` | Resize |

## CLI Control

Control Zellij from inside a session:

```bash
# Panes
zellij run -- htop                  # Run command in new pane
zellij run -f -- tail -f /var/log/* # Floating pane
zellij edit ./file.rs               # Open in $EDITOR pane
zellij action new-pane -d down      # New pane direction

# Tabs
zellij action new-tab
zellij action new-tab -l dev # With layout
zellij action go-to-tab 2
zellij action rename-tab "servers"

# Session
zellij action dump-layout >layout.kdl
zellij list-sessions
zellij kill-session my-session
```

### Useful Aliases (from completions)

```bash
zr  # zellij run --
zrf # zellij run -f --  (floating)
ze  # zellij edit
```

## Configuration

Config location:
`~/.config/zellij/config.kdl`

```bash
mkdir -p ~/.config/zellij
zellij setup --dump-config >~/.config/zellij/config.kdl
```

```kdl
// config.kdl
theme "catppuccin-mocha"
default_shell "fish"
pane_frames false
default_layout "compact"

keybinds {
    normal {
        bind "Alt n" { NewPane; }
        bind "Alt h" { MoveFocusOrTab "Left"; }
    }
}
```

## Layouts (KDL format)

```kdl
// ~/.config/zellij/layouts/dev.kdl
layout {
    pane size=1 borderless=true {
        plugin location="tab-bar"
    }
    pane split_direction="vertical" {
        pane command="nvim"
        pane split_direction="horizontal" {
            pane command="lazygit"
            pane  // empty shell
        }
    }
    pane size=2 borderless=true {
        plugin location="status-bar"
    }
}
```

Apply layout:

```bash
zellij --layout dev
zellij --layout ~/.config/zellij/layouts/dev.kdl
```

## Session Management

```bash
# List sessions
zellij list-sessions
zellij ls

# Attach
zellij attach <name>
zellij a <name>
zellij attach -c <name>  # Create if missing

# Kill
zellij kill-session <name>
zellij kill-all-sessions

# Delete (from inside session)
zellij action detach
```

## See Also

- `REFERENCE.md` for advanced layouts, plugins, tmux migration
- <https://zellij.dev/documentation>
