-- Python Development
-- All Python-related tooling: LSP, formatting, linting, virtual environments

return {
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

  -- ruff LSP is managed by miser.nvim from the active mise configuration.

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
