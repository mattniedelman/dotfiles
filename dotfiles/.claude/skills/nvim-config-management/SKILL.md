---
name: nvim-config-management
description: Use when reviewing, updating, or troubleshooting Neovim configuration including plugins, keymaps, LSP setup, LazyVim extras, or understanding plugin interactions and dependencies
---

# Neovim Config Management

Guide for managing the Neovim configuration workspace (`~/.config/nvim`).

For the Basic Memory integration (note structure, queries, example notes), an
annotated lazy.nvim plugin-spec example, and the `<leader>` keymap prefix table,
see [reference.md](reference.md).

## Configuration Structure

```text
~/.config/nvim/
├── init.lua              # Entry point (loads config.lazy)
├── lazyvim.json          # LazyVim extras and version tracking
├── lazy-lock.json        # Plugin version lockfile
├── stylua.toml           # Lua formatting config
└── lua/
    ├── config/           # Core configuration
    │   ├── lazy.lua      # Lazy.nvim bootstrap and setup
    │   ├── options.lua   # Vim options (loaded first)
    │   ├── keymaps.lua   # Global keymaps (VeryLazy)
    │   ├── autocmds.lua  # Autocommands (VeryLazy)
    │   └── chezmoi.lua   # Chezmoi-specific config
    └── plugins/          # Plugin specs (one file per concern)
        ├── ai.lua        # AI tools: augment.vim, sidekick.nvim
        ├── lsp.lua       # Core LSP infrastructure
        ├── python.lua    # Python-specific (ruff, zuban)
        ├── shell.lua     # Shell LSPs (bash, fish, awk)
        ├── formatting.lua
        ├── completion.lua
        ├── diagnostics.lua
        ├── git.lua
        ├── navigation.lua
        ├── terminal.lua
        ├── theme.lua
        ├── ui.lua
        └── ...
```

## Plugin Organization Convention

Plugins are organized by **concern**, not by plugin name:

| File | Purpose | Example Plugins |
| ------ | --------- | ----------------- |
| `ai.lua` | AI assistants | augment.vim, sidekick.nvim |
| `lsp.lua` | Core LSP + general servers | mason, mason-lspconfig |
| `python.lua` | Python ecosystem | ruff, zuban LSPs |
| `shell.lua` | Shell languages | bashls, fish_lsp |
| `markup.lua` | Markup/data formats | yamlls, marksman, jqls |
| `git.lua` | Git integration | fugitive, gitsigns |
| `completion.lua` | Completion engines | nvim-cmp, snippets |

## Key Patterns

### Adding a New Plugin

1. Identify the correct file by concern (or create new if none fits)
2. Use LazyVim plugin spec format:

```lua
return {
  {
    "author/plugin-name",
    lazy = true,  -- or false for immediate load
    event = "VeryLazy",  -- or BufRead, etc.
    opts = {
      -- plugin options
    },
    keys = {
      { "<leader>xx", function() end, desc = "Description" },
    },
  },
}
```

### Adding LSP Servers

LSP servers are managed via mason-lspconfig in `lua/plugins/lsp.lua`:

```lua
-- In lsp.lua for general servers
opts = {
  ensure_installed = {
    "lua_ls",
    "docker_language_server",
  },
},

-- Language-specific servers go in their respective files
-- e.g., ruff goes in python.lua
```

### Adding Keymaps

Global keymaps:
`lua/config/keymaps.lua` Plugin keymaps:
In the plugin spec's `keys` table

### LazyVim Extras

Managed in `lazyvim.json`.
Enable via `:LazyExtras` or manually:

```json
{
  "extras": [
    "lazyvim.plugins.extras.lang.python",
    "lazyvim.plugins.extras.coding.mini-surround"
  ]
}
```

## Common Tasks

### Audit Plugin Configuration

```lua
-- List all plugin files
list_directory("~/.config/nvim/lua/plugins/")

-- Check lazy-lock for versions
view("~/.config/nvim/lazy-lock.json")

-- Review LazyVim extras
view("~/.config/nvim/lazyvim.json")
```

### Troubleshoot LSP Issues

1. Check mason-installed servers:
   `:Mason`
2. Review LSP config in respective plugin file
3. Check `:LspInfo` for attached clients
4. Review autocmds in `lua/config/autocmds.lua` for cleanup

### Debug Plugin Loading

- Use `:Lazy` to see plugin status
- Check `lazy = true/false` in plugin spec
- Review `event`, `ft`, `cmd`, `keys` triggers

## External Dependencies

| Component | Dependency | Purpose |
| ----------- | ------------ | --------- |
| `options.lua` | mise shims | Tool version management |
| `stylua.toml` | stylua | Lua formatting |
| `ai.lua` | auggie CLI | Sidekick AI integration |
| Various LSPs | mason.nvim | LSP server installation |

## Load Order

1. `init.lua` → requires `config.lazy`
2. `config/options.lua` (before plugins)
3. LazyVim core plugins
4. `plugins/*.lua` (your overrides)
5. `config/keymaps.lua` (VeryLazy event)
6. `config/autocmds.lua` (VeryLazy event)

## Formatting

Use stylua for Lua files:

```bash
stylua --config-path ~/.config/nvim/stylua.toml <file>
```

Current config:
2-space indent, 120 column width.

## Basic Memory Integration

**REQUIRED**:
Track configuration decisions and changes in basic-memory to inform future
choices.
For note structure, query snippets, and example notes, see
[reference.md](reference.md#basic-memory-integration).
