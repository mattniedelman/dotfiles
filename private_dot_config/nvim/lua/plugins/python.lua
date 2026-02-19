-- Python Development
-- All Python-related tooling: LSP, formatting, linting, virtual environments

return {
  -- Python LSP servers via Mason
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "ruff", -- Python linter/formatter LSP
      },
      -- Disable auto-enable for zuban (use ty instead)
      automatic_enable = {
        exclude = { "zuban" },
      },
    },
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    },
  },

  -- ty: Astral's Python type checker and LSP
  -- Install via: mise use -g ty (or uv tool install ty)
  -- Now has native nvim-lspconfig support - just needs to be in servers list
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ty = {},
      },
    },
  },

  -- Install Python formatters/linters
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "ruff", -- Python linter and formatter (CLI tool)
      },
    },
  },

  -- Configure Python formatters
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.python = { "ruff_format", "ruff_organize_imports", "ruff_fix" }

      opts.formatters = opts.formatters or {}
      opts.formatters.ruff_fix = {
        command = "ruff",
        args = {
          "check",
          "--fix",
          "--force-exclude",
          "--exit-zero",
          "--no-cache",
          "--unfixable=F401",
          "--stdin-filename",
          "$FILENAME",
          "-",
        },
        stdin = true,
        cwd = require("conform.util").root_file({
          "pyproject.toml",
          "ruff.toml",
          ".ruff.toml",
        }),
      }
    end,
  },

  -- Python virtual environment selector
  {
    "linux-cultist/venv-selector.nvim",
  },
}
