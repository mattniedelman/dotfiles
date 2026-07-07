-- Shell Scripting
-- Shell script development: Bash, Fish, AWK

return {
  -- LSP servers for shell languages
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "bashls", -- Bash
        "fish_lsp", -- Fish
        "awk_ls", -- AWK
      },
    },
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    },
  },

  -- Install shell formatters/linters
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "shfmt", -- Shell script formatter
        "shellcheck", -- Shell script linter
        -- Note: fish_indent is built-in with fish shell
      },
    },
  },

  -- Configure shell formatters
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.fish = { "fish_indent" }
      opts.formatters_by_ft.sh = { "shfmt", "shellcheck" }
    end,
  },
}
