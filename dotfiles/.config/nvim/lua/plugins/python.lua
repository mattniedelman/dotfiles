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
    },
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    },
  },

  -- pyrefly: Meta's Python type checker and LSP
  -- Install via: pipx install pyrefly (or mise use -g pyrefly)
  -- Aligns with hk pyrefly step in ecosystems/python.pkl
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyrefly = {},
      },
    },
  },

  -- Note: ruff is installed via mason-lspconfig ensure_installed above; the
  -- same package provides the CLI binary the conform formatters below invoke,
  -- so no separate mason.nvim ensure_installed entry is needed.

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
