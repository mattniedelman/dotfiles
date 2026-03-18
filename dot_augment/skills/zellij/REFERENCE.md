# Zellij Extended Reference

## Advanced Layouts

### Pane Options

```kdl
layout {
    pane command="nvim" {
        args "./src"
        cwd "/home/user/project"
        start_suspended true  // Wait for keypress
        close_on_exit true
        focus true
    }
}
```

### Tabs in Layouts

```kdl
layout {
    tab name="code" {
        pane command="nvim"
    }
    tab name="servers" {
        pane command="npm" {
            args "run" "dev"
        }
        pane command="tail" {
            args "-f" "/var/log/app.log"
        }
    }
    tab name="git" {
        pane command="lazygit"
    }
}
```

### Floating Panes

```kdl
layout {
    pane
    floating_panes {
        pane command="htop" {
            x 10
            y 5
            width "50%"
            height "50%"
        }
    }
}
```

### Stacked Panes

```kdl
layout {
    pane stacked=true {
        pane command="htop" name="System"
        pane command="btop" name="Btop"
        pane name="Shell"
    }
}
```

## Custom Keybindings

```kdl
// config.kdl
keybinds clear-defaults=true {
    normal {
        bind "Ctrl g" { SwitchToMode "locked"; }
        bind "Ctrl p" { SwitchToMode "pane"; }
        bind "Ctrl t" { SwitchToMode "tab"; }
        bind "Alt n" { NewPane; }
        bind "Alt h" "Alt Left" { MoveFocusOrTab "Left"; }
        bind "Alt l" "Alt Right" { MoveFocusOrTab "Right"; }
    }
    pane {
        bind "Esc" { SwitchToMode "normal"; }
        bind "h" "Left" { MoveFocus "Left"; }
        bind "l" "Right" { MoveFocus "Right"; }
        bind "j" "Down" { MoveFocus "Down"; }
        bind "k" "Up" { MoveFocus "Up"; }
        bind "n" { NewPane; SwitchToMode "normal"; }
        bind "d" { NewPane "Down"; SwitchToMode "normal"; }
        bind "r" { NewPane "Right"; SwitchToMode "normal"; }
        bind "x" { CloseFocus; SwitchToMode "normal"; }
        bind "f" { ToggleFocusFullscreen; SwitchToMode "normal"; }
        bind "w" { ToggleFloatingPanes; SwitchToMode "normal"; }
    }
    locked {
        bind "Ctrl g" { SwitchToMode "normal"; }
    }
}
```

## Plugins

Zellij has built-in plugins and supports custom WASM plugins.

### Built-in Plugins

```kdl
layout {
    pane size=1 borderless=true {
        plugin location="tab-bar"
    }
    pane
    pane size=2 borderless=true {
        plugin location="status-bar"
    }
}
```

### Load External Plugin

```bash
zellij action launch-or-focus-plugin file:/path/to/plugin.wasm
zellij action launch-or-focus-plugin zellij:strider --floating
```

## tmux Migration

| tmux | Zellij |
|------|--------|
| `Ctrl+b` prefix | Modal (no prefix) |
| `Ctrl+b %` | `Ctrl+p r` (pane right) |
| `Ctrl+b "` | `Ctrl+p d` (pane down) |
| `Ctrl+b x` | `Ctrl+p x` (close pane) |
| `Ctrl+b c` | `Ctrl+t n` (new tab) |
| `Ctrl+b d` | `Ctrl+o d` (detach) |
| `tmux new -s name` | `zellij -s name` |
| `tmux attach -t name` | `zellij attach name` |
| `tmux ls` | `zellij list-sessions` |

### tmux-like Keybindings

```kdl
// Enable tmux mode in config.kdl
keybinds {
    tmux {
        bind "Ctrl b" { SwitchToMode "tmux"; }
    }
}
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `ZELLIJ` | Set when inside a zellij session |
| `ZELLIJ_SESSION_NAME` | Current session name |
| `ZELLIJ_PANE_ID` | Current pane ID |

```bash
# Prevent nesting
if [ -z "$ZELLIJ" ]; then
 zellij attach -c main
fi
```

## Scripting with CLI

```bash
#!/bin/bash
# Create a dev environment

zellij -s dev --layout compact

# In another script, run inside the session:
zellij --session dev run -- npm run dev
zellij --session dev action new-tab -n "logs"
zellij --session dev run -- tail -f /var/log/app.log
```

## Themes

```kdl
// config.kdl
themes {
    custom {
        fg "#d4be98"
        bg "#1d2021"
        black "#1d2021"
        red "#ea6962"
        green "#a9b665"
        yellow "#d8a657"
        blue "#7daea3"
        magenta "#d3869b"
        cyan "#89b482"
        white "#d4be98"
        orange "#e78a4e"
    }
}

theme "custom"
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Nested sessions | Check `$ZELLIJ` env var before starting |
| Keys not working | Check mode (bottom bar), press `Esc` |
| Layout not found | Use full path or place in `~/.config/zellij/layouts/` |
| Config not loading | Run `zellij setup --check` |
