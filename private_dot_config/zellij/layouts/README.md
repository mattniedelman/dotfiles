# Zellij Layouts for Multi-Auggie Sessions

Layouts for running concurrent auggie sessions across different projects and
task-focused tabs.

## Layout Files

| Layout | Purpose |
| --- | --- |
| `default.kdl` | General-purpose shell + auggie layout with swap layouts |
| `auggie-project.kdl` | Single project with stacked utility panes |
| `auggie-multi.kdl` | Multi-tab template for parallel features or tasks |

## Starting Layouts

### Start a fresh session

```bash
zellij -l ~/.config/zellij/layouts/default.kdl
zellij -l ~/.config/zellij/layouts/auggie-project.kdl
zellij -l ~/.config/zellij/layouts/auggie-multi.kdl
```

### Open a layout from an existing session

Use the built-in layout manager from `config.kdl`:

| Keys | Action |
| --- | --- |
| `Alt+l` | Open the built-in layout manager |
| `Alt+[` / `Alt+]` | Cycle swap layouts in the current tab |

## Other Useful Keybindings

| Keys | Action |
| --- | --- |
| `Alt+1-9` | Jump to tab N |
| `Alt+t` / `Ctrl+Shift+t` | New tab |
| `Ctrl+Shift+Left/Right` | Move between tabs |
| `Alt+w` | Open the session manager |
| `Ctrl+h/j/k/l` | Navigate panes in unlocked mode |
