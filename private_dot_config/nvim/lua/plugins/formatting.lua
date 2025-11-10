-- Code Formatting & Style
-- Base formatting configuration for all languages
-- Language-specific files (python.lua, shell.lua, etc.) extend this configuration

return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- Formatters
        "stylua", -- Lua formatter
        "gofumpt", -- Go formatter
        "goimports", -- Go imports formatter
        "sqlfmt", -- SQL formatter
        "typos", -- Source code spell checker
        "prettier", -- Multi-language formatter (used for markdown)
        -- Note: d2 formatter not available in Mason, install manually if needed

        -- Markdown tools (also installed by LazyVim lang.markdown extra)
        "markdown-toc",
        "markdownlint-cli2",
      },
    },
  },

  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        go = { "gofumpt", "goimports" },
        -- Markdown: Use prettier first (from LazyVim), then mdslw for line wrapping
        -- Note: LazyVim lang.markdown extra also adds markdownlint-cli2 and markdown-toc
        markdown = { "prettier", "mdslw" },
        sql = { "sqlfmt" },
        dbt = { "sqlfmt" },
        -- d2 = { "d2fmt" }, -- d2 not available in Mason
        ["*"] = { "trim_whitespace", "trim_newlines", "typos" },
      },
      formatters = {
        -- Custom formatters can be defined here
        -- Language-specific files will extend this
      },
    },
  },
}

