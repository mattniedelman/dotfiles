# VSCode Neovim Configuration

This directory contains VSCode configuration files that replicate your Neovim setup using the VSCode Neovim extension.

## Quick Start

### Automated Installation (Linux/macOS)

```bash
cd vscode-config
./install.sh
```

The script will:
1. Install all required VSCode extensions
2. Backup your existing VSCode configuration
3. Copy the new configuration files
4. Update the Neovim path automatically

### Manual Installation

1. **Install VSCode Extensions**:
   ```bash
   # Core extensions
   code --install-extension asvetliakov.vscode-neovim
   code --install-extension ms-python.python
   code --install-extension detachhead.basedpyright
   code --install-extension charliermarsh.ruff
   code --install-extension augmentcode.augment
   
   # See MAPPING.md for the complete list
   ```

2. **Copy Configuration Files**:
   
   **Linux**:
   ```bash
   cp settings.json ~/.config/Code/User/settings.json
   cp keybindings.json ~/.config/Code/User/keybindings.json
   ```
   
   **macOS**:
   ```bash
   cp settings.json ~/Library/Application\ Support/Code/User/settings.json
   cp keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
   ```
   
   **Windows**:
   ```powershell
   Copy-Item settings.json $env:APPDATA\Code\User\settings.json
   Copy-Item keybindings.json $env:APPDATA\Code\User\keybindings.json
   ```

3. **Restart VSCode**

## Files in This Directory

- **`settings.json`**: Main VSCode settings file
  - Editor settings matching Neovim behavior
  - LSP configuration (basedpyright, ruff)
  - Formatter configuration
  - VSCode Neovim extension settings
  - Language-specific settings

- **`keybindings.json`**: Custom keybindings
  - LazyVim-style keybindings with Space as leader
  - LSP action keybindings
  - File navigation shortcuts
  - Git integration shortcuts
  - Augment AI completion shortcuts

- **`MAPPING.md`**: Comprehensive documentation
  - Complete plugin mapping (Neovim → VSCode)
  - Settings mapping
  - Keybinding reference
  - Installation instructions
  - Troubleshooting guide
  - Limitations and workarounds

- **`install.sh`**: Automated installation script (Linux/macOS)
  - Installs all required extensions
  - Backs up existing configuration
  - Copies configuration files
  - Updates Neovim path

- **`README.md`**: This file

## Key Features

### ✅ What Works Perfectly

- **Neovim Integration**: Your full Neovim config runs inside VSCode
- **Vim Motions**: All Vim motions and editing commands work
- **Custom Keybindings**: `fd` to escape, Space as leader, etc.
- **LSP Features**: Go to definition, references, hover, rename, etc.
- **Formatting**: Format on save with ruff, stylua, shfmt, etc.
- **Git Integration**: Full Git support via VSCode and GitLens
- **AI Completion**: Augment Code with Ctrl+F or Ctrl+Y
- **Relative Line Numbers**: Just like in Neovim
- **Treesitter Textobjects**: Most textobjects work via embedded Neovim

### ⚠️ What's Different

- **Fuzzy Finder**: VSCode Quick Open instead of Telescope (less powerful)
- **File Explorer**: VSCode Explorer instead of Neo-tree (different UI)
- **Color Scheme**: Kanagawa theme (may differ slightly from Neovim)
- **Completion UI**: VSCode IntelliSense instead of blink.cmp

### ❌ What Doesn't Work

- **vim-kitty-navigator**: Terminal-specific, not applicable in VSCode
- **vim-slime/yarepl**: Use VSCode's "Run Selection" or Jupyter instead
- **Neovim-specific UI**: Dashboard, notifications, etc.

## Common Keybindings

All keybindings use **Space** as the leader key.

### File Navigation
- `Space f f` - Find files
- `Space f g` - Search in files (grep)
- `Space e` - Toggle file explorer
- `Space f r` - Recent files
- `Space f t` - Toggle terminal

### LSP Actions
- `g d` - Go to definition
- `g r` - Go to references
- `K` - Show hover documentation
- `Space c r` - Rename symbol
- `Space c a` - Code actions
- `Space c f` - Format document

### Buffer Management
- `Space b d` - Close buffer
- `] b` - Next buffer
- `[ b` - Previous buffer

### Git
- `Space g s` - Git status
- `Space g b` - Git blame
- `] h` - Next hunk
- `[ h` - Previous hunk

### Diagnostics
- `] d` - Next diagnostic
- `[ d` - Previous diagnostic
- `Space c d` - Show diagnostics

### AI Completion
- `Ctrl+F` or `Ctrl+Y` - Accept Augment suggestion

See `MAPPING.md` for the complete keybinding reference.

## Configuration Highlights

### Python Development

Your Python setup is fully replicated:
- **LSP**: basedpyright (matching `vim.g.lazyvim_python_lsp`)
- **Linter/Formatter**: ruff (matching `vim.g.lazyvim_python_ruff`)
- **Format on Save**: Enabled with ruff
- **Organize Imports**: Automatic with ruff
- **Virtual Environment**: Auto-detection of `.venv`

### Editor Behavior

Matches your Neovim settings:
- Relative line numbers
- No swap files (VSCode doesn't use them)
- Format on save
- Trim trailing whitespace
- Insert final newline
- 2-space indentation (4 for Python)

### Color Scheme

Configured to use Kanagawa theme (matching your `kanagawa-paper.nvim`). If not available, alternatives are suggested in `MAPPING.md`.

## Troubleshooting

### Neovim Not Detected

1. Verify Neovim is installed: `nvim --version`
2. Check the path in `settings.json`:
   ```json
   "vscode-neovim.neovimExecutablePaths.linux": "/usr/bin/nvim"
   ```
3. Update the path to match your Neovim installation
4. Restart VSCode

### Keybindings Not Working

1. Ensure you're in Normal mode (press `Esc`)
2. Check VSCode's Keyboard Shortcuts editor for conflicts
3. Verify the keybinding condition matches (e.g., `vim.mode == 'Normal'`)

### LSP Not Working

1. Verify the language extension is installed
2. Check the Output panel: View → Output → select the extension
3. Restart the language server: `Ctrl+Shift+P` → "Restart Language Server"

### Formatting Not Working

1. Verify the formatter extension is installed
2. Check `editor.formatOnSave` is enabled
3. Verify the default formatter is set for the language

See `MAPPING.md` for more detailed troubleshooting.

## Customization

### Changing the Color Theme

Edit `settings.json`:
```json
"workbench.colorTheme": "Tokyo Night"
```

Available themes (after installing extensions):
- Kanagawa
- Tokyo Night
- Gruvbox Material

### Adjusting Keybindings

Edit `keybindings.json` to customize keybindings. Use VSCode's Keyboard Shortcuts editor (`Ctrl+K Ctrl+S`) to find and modify keybindings visually.

### Adding More Formatters

Edit the `"[language]"` sections in `settings.json`:
```json
"[javascript]": {
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true
}
```

## Additional Resources

- **VSCode Neovim Extension**: https://github.com/vscode-neovim/vscode-neovim
- **LazyVim Documentation**: https://www.lazyvim.org/
- **VSCode Keybindings**: https://code.visualstudio.com/docs/getstarted/keybindings
- **Augment Code**: https://www.augmentcode.com/

## Support

For issues specific to:
- **VSCode Neovim integration**: Check the [VSCode Neovim GitHub](https://github.com/vscode-neovim/vscode-neovim/issues)
- **Neovim configuration**: Your existing Neovim config should work as-is
- **VSCode settings**: Check the [VSCode documentation](https://code.visualstudio.com/docs)

## Notes

- Your Neovim configuration at `~/.config/nvim` is used directly by the VSCode Neovim extension
- Changes to your Neovim config will automatically apply in VSCode
- Some Neovim plugins (like telescope, neo-tree) won't affect VSCode's UI
- LSP and completion are handled by VSCode extensions for better integration
- The configuration disables some VSCode features that conflict with Neovim (hover, lightbulb, etc.)

Enjoy your Neovim experience in VSCode! 🎉

