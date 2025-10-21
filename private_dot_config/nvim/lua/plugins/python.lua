return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft.python = { "ruff_format", "ruff_organize_imports", "ruff_fix" }

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
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "ruff",
        "zuban",
      },
    },
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    },
  },
}
