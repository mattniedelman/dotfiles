# Quick Reference Guide

## Installation (One Command)

```bash
cd vscode-config && ./install.sh
```

Then restart VSCode.

---

## Essential Keybindings

**Leader Key**: `Space`

### Most Used Commands

| Action | Keybinding |
|--------|------------|
| Find files | `Space f f` |
| Search in files | `Space f g` |
| File explorer | `Space e` |
| Save file | `Space w` |
| Close buffer | `Space b d` |
| Command palette | `Space Space` |
| Toggle terminal | `Space f t` or `Ctrl+/` |

### LSP (Code Intelligence)

| Action | Keybinding |
|--------|------------|
| Go to definition | `g d` |
| Go to references | `g r` |
| Show documentation | `Shift+K` |
| Rename symbol | `Space c r` |
| Code actions | `Space c a` |
| Format document | `Space c f` |
| Next error | `] d` |
| Previous error | `[ d` |

### AI Completion (Augment)

| Action | Keybinding |
|--------|------------|
| Accept suggestion | `Ctrl+F` or `Ctrl+Y` |

### Vim Essentials

| Action | Keybinding |
|--------|------------|
| Escape insert mode | `Esc` or `fd` |
| Visual mode | `v` |
| Visual line mode | `Shift+V` |
| Visual block mode | `Ctrl+V` |

---

## Required Extensions

Install these from VSCode marketplace:

### Core (Must Have)
- `asvetliakov.vscode-neovim` - Neovim integration
- `augmentcode.augment` - AI completion
- `detachhead.basedpyright` - Python LSP
- `charliermarsh.ruff` - Python formatter/linter

### Recommended
- `eamodio.gitlens` - Git integration
- `PKief.material-icon-theme` - File icons
- `usernamehw.errorlens` - Inline errors
- `qufiwefefwoyn.kanagawa` - Color theme

---

## Configuration Files

| File | Location (Linux) | Purpose |
|------|------------------|---------|
| `settings.json` | `~/.config/Code/User/` | Editor settings, LSP, formatters |
| `keybindings.json` | `~/.config/Code/User/` | Custom keybindings |

---

## Python Setup

Your Python configuration is automatically replicated:

- **LSP**: basedpyright
- **Formatter**: ruff
- **Linter**: ruff
- **Format on save**: ✅ Enabled
- **Organize imports**: ✅ Automatic
- **Virtual env**: Auto-detects `.venv`

To select Python interpreter: `Space c v`

---

## What Works vs. What Doesn't

### ✅ Works Perfectly
- All Vim motions and editing
- LSP features (go to def, references, etc.)
- Format on save
- Git integration
- AI completion (Augment)
- Custom keybindings (`fd` to escape, etc.)
- Relative line numbers

### ⚠️ Different but Functional
- File finder (VSCode Quick Open vs. Telescope)
- File explorer (VSCode Explorer vs. Neo-tree)
- Color scheme (may look slightly different)

### ❌ Doesn't Work
- vim-kitty-navigator (terminal-specific)
- vim-slime/yarepl (use Jupyter or "Run Selection" instead)

---

## Troubleshooting

### Neovim not detected
```bash
# Check Neovim is installed
nvim --version

# Update path in settings.json
"vscode-neovim.neovimExecutablePaths.linux": "/usr/bin/nvim"
```

### Keybindings not working
1. Press `Esc` to enter Normal mode
2. Check for conflicts: `Ctrl+K Ctrl+S`
3. Restart VSCode

### Python LSP not working
1. Install basedpyright extension
2. Select Python interpreter: `Space c v`
3. Restart language server: `Ctrl+Shift+P` → "Restart Language Server"

---

## Next Steps

1. ✅ Run `./install.sh`
2. ✅ Restart VSCode
3. ✅ Open a file and test Vim motions
4. ✅ Try `Space f f` to find files
5. ✅ Try `g d` to go to definition
6. ✅ Test AI completion with `Ctrl+F`

---

## Full Documentation

- **Complete guide**: See `MAPPING.md`
- **Installation details**: See `README.md`
- **Your Neovim config**: `~/.config/nvim/`

---

## Quick Tips

1. **Your Neovim config runs inside VSCode** - any changes to `~/.config/nvim/` apply automatically
2. **Use Space as leader** - just like in LazyVim
3. **LSP is handled by VSCode** - for better integration
4. **Format on save is enabled** - your code will auto-format
5. **Git integration is built-in** - use `Space g s` for Git status

---

## Getting Help

- VSCode Neovim: https://github.com/vscode-neovim/vscode-neovim
- LazyVim: https://www.lazyvim.org/
- VSCode Docs: https://code.visualstudio.com/docs

Enjoy! 🎉

