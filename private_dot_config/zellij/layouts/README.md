# Zellij Layouts

## Layout Files

| Layout | Purpose |
| --- | --- |
| `project-sidebar.kdl` | Default session layout: tab-bar + zjstatus bar, swap layouts for pane arrangement |

This is the `default_layout` set in `config.kdl`, so any new `zellij` session
without an explicit `-l` flag uses it automatically.

## Starting a Session

```bash
zellij                                              # uses project-sidebar.kdl by default
zellij -l ~/.config/zellij/layouts/project-sidebar.kdl
```

## Other Useful Keybindings

| Keys | Action |
| --- | --- |
| `Alt+l` | Open the built-in layout manager |
| `Alt+[` / `Alt+]` | Cycle swap layouts (`focus` / `equal` / `trio`) in the current tab |
| `Alt+1-9` | Jump to tab N |
| `Alt+t` / `Ctrl+Shift+t` | New tab |
| `Ctrl+Shift+Left/Right` | Move between tabs |
| `Alt+w` | Open the session manager |
| `Ctrl+h/j/k/l` | Navigate panes in unlocked mode |
| `f` (pane mode) / `Ctrl+Alt+z` | Toggle fullscreen for the focused pane -- this also hides the tab-bar/status bar for that tab since they're sibling panes; toggle again to bring them back |
