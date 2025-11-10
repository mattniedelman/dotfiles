# Neovim to VSCode Configuration Mapping

This document provides a comprehensive mapping between your Neovim configuration and the equivalent VSCode setup using the VSCode Neovim extension.

## Table of Contents
- [Installation Instructions](#installation-instructions)
- [Plugin Mapping](#plugin-mapping)
- [Settings Mapping](#settings-mapping)
- [Keybinding Mapping](#keybinding-mapping)
- [Limitations and Workarounds](#limitations-and-workarounds)

---

## Installation Instructions

### 1. Install Required VSCode Extensions

Install the following extensions from the VSCode marketplace:

#### Core Extensions (Required)
```bash
# VSCode Neovim integration
code --install-extension asvetliakov.vscode-neovim

# Python development
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension detachhead.basedpyright
code --install-extension charliermarsh.ruff

# Augment Code (AI completion)
code --install-extension augmentcode.augment

# Language support
code --install-extension golang.go
code --install-extension redhat.vscode-yaml
code --install-extension ms-azuretools.vscode-docker
code --install-extension tamasfe.even-better-toml
```

#### Recommended Extensions
```bash
# Git integration
code --install-extension eamodio.gitlens
code --install-extension mhutchie.git-graph

# UI enhancements
code --install-extension PKief.material-icon-theme
code --install-extension usernamehw.errorlens
code --install-extension oderwat.indent-rainbow
code --install-extension Gruntfuggly.todo-tree

# Formatters
code --install-extension JohnnyMorganz.stylua
code --install-extension foxundermoon.shell-format

# Color themes
code --install-extension qufiwefefwoyn.kanagawa
# Note: If Kanagawa is not available, alternatives:
# code --install-extension enkia.tokyo-night
# code --install-extension sainnhe.gruvbox-material
```

### 2. Copy Configuration Files

Copy the generated configuration files to your VSCode settings directory:

**Linux:**
```bash
# Copy settings
cp vscode-config/settings.json ~/.config/Code/User/settings.json

# Copy keybindings
cp vscode-config/keybindings.json ~/.config/Code/User/keybindings.json
```

**macOS:**
```bash
# Copy settings
cp vscode-config/settings.json ~/Library/Application\ Support/Code/User/settings.json

# Copy keybindings
cp vscode-config/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
```

**Windows:**
```powershell
# Copy settings
Copy-Item vscode-config\settings.json $env:APPDATA\Code\User\settings.json

# Copy keybindings
Copy-Item vscode-config\keybindings.json $env:APPDATA\Code\User\keybindings.json
```

### 3. Configure Neovim Path

Update the Neovim executable path in `settings.json` if your Neovim is installed in a different location:

```json
"vscode-neovim.neovimExecutablePaths.linux": "/usr/bin/nvim",  // Linux
"vscode-neovim.neovimExecutablePaths.darwin": "/usr/local/bin/nvim",  // macOS
"vscode-neovim.neovimExecutablePaths.win32": "C:\\Program Files\\Neovim\\bin\\nvim.exe",  // Windows
```

### 4. Verify Neovim Integration

1. Open VSCode
2. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS)
3. Type "Neovim" and select "Neovim: Show Neovim Information"
4. Verify that Neovim is detected and your config is loaded

---

## Plugin Mapping

### Core Plugins

| Neovim Plugin | VSCode Extension | Notes |
|---------------|------------------|-------|
| **LazyVim** | VSCode Neovim Extension | LazyVim runs inside VSCode via the Neovim extension |
| **lazy.nvim** | N/A | Plugin manager runs in embedded Neovim |
| **augment.vim** | Augment Code Extension | AI code completion; use Ctrl+F or Ctrl+Y to accept |
| **blink.cmp** | VSCode IntelliSense | Completion handled by VSCode; Neovim completion disabled in VSCode context |
| **conform.nvim** | VSCode Formatters | Formatters configured in `settings.json` per language |
| **nvim-lspconfig** | VSCode LSP Extensions | LSP handled by VSCode extensions (basedpyright, ruff, etc.) |
| **nvim-treesitter** | VSCode Semantic Highlighting | Syntax highlighting handled by VSCode and language extensions |

### UI and Navigation

| Neovim Plugin | VSCode Extension | Notes |
|---------------|------------------|-------|
| **neo-tree.nvim** | VSCode Explorer | Use `Space+e` to toggle file explorer |
| **telescope.nvim** | VSCode Quick Open | `Space+ff` for files, `Space+fg` for grep |
| **which-key.nvim** | N/A | VSCode shows keybinding hints in status bar |
| **kanagawa-paper.nvim** | Kanagawa Theme Extension | Install Kanagawa theme extension |
| **flexoki-nvim** | N/A | Not available; use Kanagawa or Tokyo Night instead |

### Git Integration

| Neovim Plugin | VSCode Extension | Notes |
|---------------|------------------|-------|
| **gitsigns.nvim** | GitLens + Built-in Git | Git integration via VSCode's native Git and GitLens |
| **lazygit.nvim** | GitLens | Use GitLens for advanced Git features |

### Language-Specific

| Neovim Plugin | VSCode Extension | Notes |
|---------------|------------------|-------|
| **venv-selector.nvim** | Python Extension | Use `Space+cv` to select Python interpreter |
| **vim-slime** | N/A | Use VSCode's "Run Selection in Terminal" or Jupyter extension |
| **yarepl.nvim** | Jupyter Extension | For interactive Python development |

### Editor Enhancements

| Neovim Plugin | VSCode Extension | Notes |
|---------------|------------------|-------|
| **better-escape.nvim** | Handled by Neovim | `fd` to escape works via embedded Neovim |
| **mini.pairs** | Auto Close Tag Extension | Disabled in your config; VSCode has built-in bracket pairing |
| **nvim-treesitter-textobjects** | VSCode Selection | Some textobjects work via Neovim; others use VSCode's smart select |
| **nvim-treesitter-context** | Sticky Scroll | Enable `editor.stickyScroll.enabled` in settings |
| **log-highlight.nvim** | Log File Highlighter Extension | Install log syntax highlighting extension |

### Terminal and Navigation

| Neovim Plugin | VSCode Extension | Notes |
|---------------|------------------|-------|
| **vim-kitty-navigator** | N/A | Not applicable in VSCode; use VSCode's split navigation |

---

## Settings Mapping

### Editor Options

| Neovim Setting | VSCode Setting | Value |
|----------------|----------------|-------|
| `vim.opt.swapfile = false` | N/A | VSCode doesn't use swap files |
| `vim.opt.number = true` | `editor.lineNumbers` | `"relative"` |
| `vim.opt.relativenumber = true` | `editor.lineNumbers` | `"relative"` |
| `vim.opt.cursorline = true` | `editor.renderLineHighlight` | `"all"` |
| `vim.opt.scrolloff = 8` | `editor.cursorSurroundingLines` | `8` |
| `vim.opt.wrap = false` | `editor.wordWrap` | `"off"` |
| `vim.opt.tabstop = 2` | `editor.tabSize` | `2` |
| `vim.opt.shiftwidth = 2` | `editor.tabSize` | `2` |
| `vim.opt.expandtab = true` | `editor.insertSpaces` | `true` |

### Python LSP Configuration

| Neovim Setting | VSCode Setting | Value |
|----------------|----------------|-------|
| `vim.g.lazyvim_python_lsp = "basedpyright"` | `python.languageServer` | `"None"` (use basedpyright extension) |
| `vim.g.lazyvim_python_ruff = "ruff"` | `ruff.enable` | `true` |
| Ruff format on save | `"[python]".editor.formatOnSave` | `true` |
| Ruff organize imports | `"[python]".editor.codeActionsOnSave` | `{"source.organizeImports": "explicit"}` |

### Formatting Configuration

| Neovim Formatter | VSCode Formatter | Language |
|------------------|------------------|----------|
| `stylua` | `JohnnyMorganz.stylua` | Lua |
| `ruff_format` | `charliermarsh.ruff` | Python |
| `shfmt` | `foxundermoon.shell-format` | Shell |
| `jq` | `vscode.json-language-features` | JSON |
| `gofumpt` | `golang.go` | Go |

---

## Keybinding Mapping

### Leader Key
- **Neovim**: `Space` (LazyVim default)
- **VSCode**: `Space` (configured in keybindings.json)

### File Navigation

| Action | Neovim | VSCode | Notes |
|--------|--------|--------|-------|
| Find files | `<leader>ff` | `Space f f` | Opens Quick Open |
| Live grep | `<leader>fg` | `Space f g` | Search in files |
| File explorer | `<leader>e` | `Space e` | Toggle explorer |
| Recent files | `<leader>fr` | `Space f r` | Open recent |
| Toggle terminal | `<leader>ft` | `Space f t` | Toggle terminal |

### Buffer Management

| Action | Neovim | VSCode | Notes |
|--------|--------|--------|-------|
| Close buffer | `<leader>bd` | `Space b d` | Close editor |
| Next buffer | `]b` | `] b` | Next editor |
| Previous buffer | `[b` | `[ b` | Previous editor |

### LSP Actions

| Action | Neovim | VSCode | Notes |
|--------|--------|--------|-------|
| Go to definition | `gd` | `g d` | Jump to definition |
| Go to references | `gr` | `g r` | Show references |
| Go to implementation | `gI` | `g Shift+i` | Jump to implementation |
| Go to type definition | `gy` | `g y` | Jump to type |
| Show hover | `K` | `Shift+k` | Show documentation |
| Rename | `<leader>cr` | `Space c r` | Rename symbol |
| Code actions | `<leader>ca` | `Space c a` | Quick fix |
| Format | `<leader>cf` | `Space c f` | Format document |

### Diagnostics

| Action | Neovim | VSCode | Notes |
|--------|--------|--------|-------|
| Next diagnostic | `]d` | `] d` | Next error/warning |
| Previous diagnostic | `[d` | `[ d` | Previous error/warning |
| Show diagnostics | `<leader>cd` | `Space c d` | Problems panel |

### Git

| Action | Neovim | VSCode | Notes |
|--------|--------|--------|-------|
| Git status | `<leader>gs` | `Space g s` | Source control view |
| Git blame | `<leader>gb` | `Space g b` | Toggle line blame |
| Next hunk | `]h` | `] h` | Next change |
| Previous hunk | `[h` | `[ h` | Previous change |

### Custom Keybindings

| Action | Neovim | VSCode | Notes |
|--------|--------|--------|-------|
| Augment accept | `<C-y>` or `<C-f>` | `Ctrl+y` or `Ctrl+f` | Accept AI suggestion |
| Escape insert mode | `fd` | `fd` | Via better-escape in Neovim |
| Disabled keys | `q`, `Q` | N/A | Disabled in Neovim config |

### Window Management

| Action | Neovim | VSCode | Notes |
|--------|--------|--------|-------|
| Split vertical | `<leader>\|` | `Space \|` | Split right |
| Split horizontal | `<leader>-` | `Space -` | Split down |
| Close window | `<leader>wd` | `Space w d` | Close editor |

---

## Limitations and Workarounds

### Features That Work Seamlessly

✅ **Neovim motions and editing**: All Vim motions work perfectly via the VSCode Neovim extension  
✅ **LSP features**: Go to definition, references, hover, etc. work via VSCode's LSP  
✅ **Formatting**: Format on save works with configured formatters  
✅ **Git integration**: Full Git support via VSCode and GitLens  
✅ **Augment AI completion**: Works with Ctrl+F or Ctrl+Y  
✅ **Better-escape**: `fd` to escape works via embedded Neovim  
✅ **Treesitter textobjects**: Most textobjects work via embedded Neovim  

### Features With Limitations

⚠️ **Telescope fuzzy finder**: Replaced by VSCode's Quick Open (less powerful)  
⚠️ **Which-key**: No direct equivalent; VSCode shows some keybinding hints  
⚠️ **Neo-tree**: Replaced by VSCode Explorer (different UI)  
⚠️ **Treesitter context**: Use VSCode's Sticky Scroll instead  
⚠️ **Color schemes**: Limited theme selection; Kanagawa available but may differ slightly  

### Features That Don't Work

❌ **vim-kitty-navigator**: Terminal-specific; not applicable in VSCode  
❌ **vim-slime**: No direct equivalent; use VSCode's "Run Selection" or Jupyter  
❌ **yarepl**: Use Jupyter extension for interactive Python development  
❌ **Neovim-specific UI plugins**: Dashboard, notifications, etc. don't apply  

### Recommended Workarounds

1. **REPL Integration**: Instead of vim-slime/yarepl, use:
   - VSCode's built-in "Run Selection in Terminal" (`Shift+Enter`)
   - Jupyter extension for interactive Python notebooks
   - Python Interactive window (`Shift+Enter` in Python files)

2. **Fuzzy Finding**: VSCode's Quick Open is less powerful than Telescope, but you can:
   - Use `Ctrl+P` for file search
   - Use `Ctrl+Shift+F` for text search
   - Install "Search Everywhere" extension for better fuzzy finding

3. **Terminal Navigation**: Instead of vim-kitty-navigator:
   - Use `Ctrl+` ` to toggle terminal
   - Use `Ctrl+Shift+5` to split terminal
   - Use VSCode's split editor navigation

4. **Color Scheme**: If Kanagawa Paper is not available:
   - Use Tokyo Night theme (similar aesthetic)
   - Use Gruvbox Material
   - Or keep using your Neovim colorscheme (it will apply in the editor area)

---

## Testing Your Setup

After installation, test the following:

1. **Neovim Integration**:
   - Open a file and verify Vim motions work
   - Try `fd` in insert mode to escape
   - Verify relative line numbers are shown

2. **LSP Features**:
   - Open a Python file
   - Hover over a symbol (`Shift+K`)
   - Go to definition (`gd`)
   - Try renaming (`Space c r`)

3. **Formatting**:
   - Open a Python file
   - Make some formatting changes
   - Save the file (`Space w` or `Ctrl+S`)
   - Verify Ruff formats the code

4. **Augment AI**:
   - Start typing code
   - Wait for Augment suggestion
   - Press `Ctrl+F` or `Ctrl+Y` to accept

5. **Keybindings**:
   - Try `Space f f` to open file finder
   - Try `Space e` to toggle explorer
   - Try `Space g s` to open Git view

---

## Additional Configuration

### Enable Sticky Scroll (Treesitter Context Alternative)

Add to `settings.json`:
```json
"editor.stickyScroll.enabled": true,
"editor.stickyScroll.maxLineCount": 5
```

### Configure Python Virtual Environment

The configuration automatically looks for `.venv` in your workspace. To change:
```json
"python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python"
```

### Adjust Neovim Performance

If you experience lag, try:
```json
"vscode-neovim.neovimClean": true,
"vscode-neovim.useWsl": false
```

---

## Troubleshooting

### Neovim Not Detected
- Verify Neovim is installed: `nvim --version`
- Check the path in settings.json matches your Neovim installation
- Restart VSCode after changing settings

### Keybindings Not Working
- Check that you're in Normal mode (press `Esc`)
- Verify the keybinding condition matches (e.g., `vim.mode == 'Normal'`)
- Check for conflicts in VSCode's Keyboard Shortcuts editor

### LSP Not Working
- Verify the language extension is installed
- Check the Output panel for errors (View → Output → select extension)
- Restart the language server: `Ctrl+Shift+P` → "Restart Language Server"

### Formatting Not Working
- Verify the formatter extension is installed
- Check `editor.formatOnSave` is enabled
- Check the default formatter is set for the language

---

## Summary

This configuration replicates your Neovim setup in VSCode while leveraging VSCode's native features where appropriate. The VSCode Neovim extension runs your actual Neovim configuration, so most of your muscle memory and workflows will transfer seamlessly.

**Key Points**:
- Your Neovim config runs inside VSCode via the extension
- LSP and formatting are handled by VSCode extensions for better integration
- Most keybindings are preserved with the same leader key (Space)
- Some plugins are replaced by VSCode equivalents
- A few terminal-specific features (kitty-navigator, slime) don't apply

Enjoy your Neovim experience in VSCode! 🎉

